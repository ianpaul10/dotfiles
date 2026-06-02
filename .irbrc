require 'reline'

Reline::Face.config(:completion_dialog) do |conf|
  conf.define :default, foreground: '#E5E7EB', background: '#1F2937' # light grey on dark slate
  conf.define :enhanced, foreground: '#111827', background: '#FBBF24' # dark navy on amber
  conf.define :scrollbar, foreground: '#FBBF24', background: '#374151' # amber on medium slate
end
