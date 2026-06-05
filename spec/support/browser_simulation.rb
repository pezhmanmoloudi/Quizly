module BrowserSimulation
  MODERN_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"

  %i[get post put patch delete].each do |method|
    define_method(method) do |path, **kwargs|
      kwargs[:headers] ||= {}
      kwargs[:headers]["User-Agent"] ||= MODERN_UA
      super(path, **kwargs)
    end
  end
end

RSpec.configure { |config| config.include BrowserSimulation, type: :request }
