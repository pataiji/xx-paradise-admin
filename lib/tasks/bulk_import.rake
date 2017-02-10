namespace :image do
  desc 'bulk import images'
  task :bulk_import, [:dir_path] => :environment do |task, args|
    dir_path = args.dir_path
    if dir_path.start_with?('/')
      pattern = File.join(dir_path, '*.{jpg,jpeg,gif,png}')
    else
      pattern = Rails.root.join(dir_path, '*.{jpg,jpeg,gif,png}')
    end
    Dir.glob(pattern).each do |image_path|
      image = Image.new(data: File.open(image_path))
      image.save
    end
  end
end
