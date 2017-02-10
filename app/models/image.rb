class Image
  include ActiveModel::Model
  include Paperclip::Glue

  SDB_DOMAIN = 'xx-paradise'

  define_model_callbacks :save, :destroy

  attr_accessor :data_file_name, :data_file_size, :data_content_type, :data_updated_at, :data_width, :data_height

  has_attached_file :data,
    path: 'origin/:hash.:extension',
    hash_data: ':class/:attachment/:style/:updated_at',
    hash_secret: 'd3a8b345ad28110e62edc2e8859f57aee9370b4a65380807f66a18513cb17c6a393b1694bf85939cfd60ab3c6dd3471fe6f5a11f0d06d660752c1a509e17503f',
    storage: :s3,
    s3_credentials: {
      bucket: '',
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      s3_region: ENV.fetch('AWS_REGION'),
    }

  validates_attachment :data, presence: true, content_type: { content_type: /\Aimage\/.*\Z/ }

  before_save :extract_dimensions
  after_save :save_to_sdb

  def save
    run_callbacks :save do
      true
    end
  end

  def save_to_sdb
    sdb.put_attributes(
      domain_name: SDB_DOMAIN,
      item_name: id.to_s,
      attributes: [
        { name: 'path', value: data.path },
        { name: 'width', value: data_width.to_s },
        { name: 'height', value: data_height.to_s },
      ],
      expected: {
        name: 'ItemName()',
        exists: false,
      }
    )
  end

  def destroy
    run_callbacks :destroy do
    end
  end

  def id
    @id if @id
    result = sdb.select(
      select_expression: "select count(*) from `#{SDB_DOMAIN}`"
    )
    @id = result.dig(:items, 0, :attributes, 0, :value).to_i + 1
  end

  private

  def extract_dimensions
    tempfile = data.queued_for_write[:original]
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.data_width  = geometry.width.to_i
      self.data_height = geometry.height.to_i
    end
  end

  def sdb
    @sdb ||= Aws::SimpleDB::Client.new
  end
end
