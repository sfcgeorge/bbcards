#!/usr/bin/env ruby

# #######################################################################
#
# bbcards is loosely based on an earlier, but more simplistic project
# called cahgen that also uses ruby/prawn to generate CAH cards,
# which can be found here: https://github.com/jyruzicka/cahgen
#
# bbcards is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2 of
# the License, or (at your option) any later version.
#
# bbcards is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hadoop-Gpl-Compression. If not, see
# <http://www.gnu.org/licenses/>
#
#
# #######################################################################


require "prawn"
require "prawn/measurement_extensions"


MM_PER_INCH=25.4

PAPER_NAME   = "LETTER"
PAPER_HEIGHT = (MM_PER_INCH*11.0).mm;
PAPER_WIDTH  = (MM_PER_INCH*8.5).mm;


def get_card_geometry(card_width_inches=2.0, card_height_inches=2.0, rounded_corners=false, one_card_per_page=false)
	card_geometry = Hash.new
	card_geometry["card_width"]        = (MM_PER_INCH*card_width_inches).mm
	card_geometry["card_height"]       = (MM_PER_INCH*card_height_inches).mm

	card_geometry["rounded_corners"]   = rounded_corners == true ? ((1.0/8.0)*MM_PER_INCH).mm : rounded_corners
	card_geometry["one_card_per_page"] = one_card_per_page

	if card_geometry["one_card_per_page"]
		card_geometry["paper_width"]       = card_geometry["card_width"]
		card_geometry["paper_height"]      = card_geometry["card_height"]
	else
		card_geometry["paper_width"]       = PAPER_WIDTH
		card_geometry["paper_height"]      = PAPER_HEIGHT
	end


	card_geometry["cards_across"] = (card_geometry["paper_width"] / card_geometry["card_width"]).floor
	card_geometry["cards_high"]   = (card_geometry["paper_height"] / card_geometry["card_height"]).floor

	card_geometry["page_width"]   = card_geometry["card_width"] * card_geometry["cards_across"]
	card_geometry["page_height"]  = card_geometry["card_height"] * card_geometry["cards_high"]

	card_geometry["margin_left"]  = (card_geometry["paper_width"] - card_geometry["page_width"] ) / 2
	card_geometry["margin_top"]   = (card_geometry["paper_height"] - card_geometry["page_height"] ) / 2

	return card_geometry;

end

SAFE_MARGIN = (MM_PER_INCH*0.24 + 4).mm

def box(pdf, card_geometry, index, &blck)
	# Determine row + column number
	column = index%card_geometry["cards_across"]
	row = card_geometry["cards_high"] - index/card_geometry["cards_across"]

	# Margin: 10pt
	x = card_geometry["card_width"] * column + SAFE_MARGIN
	y = card_geometry["card_height"] * row - SAFE_MARGIN

	pdf.bounding_box([x,y], width: card_geometry["card_width"]-SAFE_MARGIN*2, height: card_geometry["card_height"]-SAFE_MARGIN*2, &blck)
end

def render_card_page(pdf, card_geometry, is_black)
  font_path = "/System/Library/Fonts/HelveticaNeue.dfont"
  #pdf.font_families["Helvetica Neue"] = {
    #:normal => { :file => file, :font => "HelveticaNeue" }
  #}
  pdf.font_families.update("Helvetica Neue" => {
    :normal      => { :file => font_path, :font => "HelveticaNeue" },
    :italic      => { :file => font_path, :font => "HelveticaNeue-Italic" },
    :bold        => { :file => font_path, :font => "HelveticaNeue-Bold" },
    :bold_italic => { :file => font_path, :font => "HelveticaNeue-BoldItalic" }
  })

	pdf.font "Helvetica Neue", :style => :normal
	pdf.font_size = 30

	if(is_black)
		pdf.canvas do
			pdf.rectangle(pdf.bounds.top_left,pdf.bounds.width, pdf.bounds.height)
		end

		pdf.fill_and_stroke(:fill_color=>"000000", :stroke_color=>"000000") do
			pdf.canvas do
				pdf.rectangle(pdf.bounds.top_left,pdf.bounds.width, pdf.bounds.height)
			end
		end
		pdf.stroke_color "ffffff"
		pdf.fill_color "ffffff"
	else
		pdf.stroke_color "000000"
		pdf.fill_color "000000"
	end

  box(pdf, card_geometry, 0) do
    card_text = 'Cards<br>Against<br>Humanity'

    #by default cards should be bold
    card_text = "<b>" + card_text + "</b>"

    pdf.text_box card_text.to_s, :overflow => :shrink_to_fit, :height => card_geometry["card_height"]-35, :inline_format => true, :leading => -7.5
  end

	pdf.stroke_color "000000"
	pdf.fill_color "000000"
end

def load_ttf_fonts(font_dir, font_families)
	if font_dir.nil?
		return
	elsif (not Dir.exist?(font_dir)) or (font_families.nil?)
		return
	end

	font_files = Hash.new
	ttf_files=Dir.glob(font_dir + "/*.ttf")
	ttf_files.each do |ttf|
		full_name = ttf.gsub(/^.*\//, "")
		full_name = full_name.gsub(/\.ttf$/, "")
		style = "normal"
		name = full_name
		if name.match(/_Bold_Italic$/)
			style = "bold_italic"
			name = name.gsub(/_Bold_Italic$/, "")
		elsif name.match(/_Italic$/)
			style = "italic"
			name = name.gsub(/_Italic$/, "")
		elsif name.match(/_Bold$/)
			style = "bold"
			name = name.gsub(/_Bold$/, "")
		end

		name = name.gsub(/_/, " ");

		if not (font_files.has_key? name)
			font_files[name] = Hash.new
		end
		font_files[name][style] = ttf
	end

	font_files.each_pair do |name, ttf_files|
		if (ttf_files.has_key? "normal" ) and (not font_families.has_key? "name" )
			normal = ttf_files["normal"]
			italic = (ttf_files.has_key? "italic") ?  ttf_files["italic"] : normal
			bold   = (ttf_files.has_key? "bold"  ) ?  ttf_files["bold"]   : normal
			bold_italic = normal
			if ttf_files.has_key? 'bold_italic'
				bold_italic = ttf_files["bold_italic"]
			elsif ttf_files.has_key? 'italic'
				bold_italic = italic
			elsif ttf_files.has_key? 'bold'
				bold_italic = bold
			end


			font_families.update(name => {
				:normal => normal,
				:italic => italic,
				:bold => bold,
				:bold_italic => bold_italic
			})

		end
	end
end


def render_cards(directory=".", white_file="white.txt", black_file="black.txt", icon_file="icon.png", output_file="cards.pdf", input_files_are_absolute=false, output_file_name_from_directory=true, recurse=true, card_geometry=get_card_geometry, white_string="", black_string="", output_to_stdout=false, title=nil )

  black_output_file = 'black_card.pdf'
  white_output_file = 'white_card.pdf'

  title = "Bigger, Blacker Cards"

  pdf = Prawn::Document.new(
    page_size: [card_geometry["paper_width"], card_geometry["paper_height"]],
    left_margin: card_geometry["margin_left"],
    right_margin: card_geometry["margin_left"],
    top_margin: card_geometry["margin_top"],
    bottom_margin: card_geometry["margin_top"],
    info: { :Title => title, :CreationDate => Time.now, :Producer => "Bigger, Blacker Cards", :Creator=>"Bigger, Blacker Cards" }
    )
  #load_ttf_fonts("/usr/share/fonts/truetype/msttcorefonts", pdf.font_families)
  render_card_page(pdf, card_geometry, true)

  pdf2 = Prawn::Document.new(
    page_size: [card_geometry["paper_width"], card_geometry["paper_height"]],
    left_margin: card_geometry["margin_left"],
    right_margin: card_geometry["margin_left"],
    top_margin: card_geometry["margin_top"],
    bottom_margin: card_geometry["margin_top"],
    info: { :Title => title, :CreationDate => Time.now, :Producer => "Bigger, Blacker Cards", :Creator=>"Bigger, Blacker Cards" }
    )
  #load_ttf_fonts("/usr/share/fonts/truetype/msttcorefonts", pdf.font_families)
  render_card_page(pdf2, card_geometry, false)

  if output_to_stdout
    puts "Content-Type: application/pdf"
    puts ""
    print pdf.render
    print pdf2.render
  else
    pdf.render_file(black_output_file)
    pdf2.render_file(white_output_file)
  end
end

def parse_args(variables=Hash.new, flags=Hash.new, save_orphaned=false, argv=ARGV)
	parsed_args = Hash.new
	orphaned = Array.new

	new_argv=Array.new
	while argv.length > 0
		next_arg = argv.shift
		if variables.has_key? next_arg
			arg_name = variables[next_arg]
			parsed_args[arg_name] = argv.shift
		elsif flags.has_key? next_arg
			flag_name = flags[next_arg]
			parsed_args[flag_name] = true
		else
			orphaned.push next_arg
		end
		new_argv.push next_arg
	end
	if save_orphaned
		parsed_args["ORPHANED_ARGUMENT_ARRAY"] = orphaned
	end

	while new_argv.length > 0
		argv.push new_argv.shift
	end

	return parsed_args
end






def print_help
	puts "USAGE:"
	puts "\tbbcards --directory [CARD_FILE_DIRECTORY]"
	puts "\tOR"
	puts "\tbbcards --white [WHITE_CARD_FILE] --black [BLACK_CARD_FILE] --icon [ICON_FILE] --output [OUTPUT_FILE]"
	puts ""
	puts "bbcards expects you to specify EITHER a directory or"
	puts "specify a path to black/white card files. If both are"
	puts "specified, it will ignore the indifidual files and generate"
       	puts "cards from the directory."
	puts ""
	puts "If you specify a directory, white cards will be loaded from"
       	puts "a file white.txt in that directory and black cards from"
	puts "black.txt. If icon.png exists in that directory, it will be"
       	puts "used to generate the card icon on the lower left hand side of"
	puts "the card. The output will be a pdf file with the same name as"
	puts "the directory you specified in the current working directory."
	puts "bbcards will descend recursively into any directory you"
	puts "specify, generating a separate pdf for every directory that"
	puts "contains black.txt, white.txt or both."
	puts ""
	puts "You may specify the card size by passing either the --small"
	puts " or --large flag.  If you pass the --small flag then small"
	puts "cards of size 2\"x2\" will be produced. If you pass the --large"
	puts "flag larger cards of size 2.5\"x3.5\" will be produced. Small"
	puts "cards are produced by default."
	puts ""
	puts "All flags:"
	puts "\t-b,--black\t\tBlack card file"
	puts "\t-d,--dir\t\tDirectory to search for card files"
	puts "\t-h,--help\t\tPrint this Help message"
	puts "\t-i,--icon\t\tIcon file, should be .jpg or .png"
	puts "\t-l,--large\t\tGenerate large 2.5\"x3.5\" cards"
	puts "\t-o,--output\t\tOutput file, will be a .pdf file"
	puts "\t-s,--small\t\tGenerate small 2\"x2\" cards"
	puts "\t-w,--white\t\tWhite card file"
	puts ""
end

arg_defs  = Hash.new
flag_defs = Hash.new
arg_defs["-b"]          = "black"
arg_defs["--black"]     = "black"
arg_defs["-w"]          = "white"
arg_defs["--white"]     = "white"
arg_defs["-d"]          = "dir"
arg_defs["--directory"] = "dir"
arg_defs["-i"]          = "icon"
arg_defs["--icon"]      = "icon"
arg_defs["-o"]          = "output"
arg_defs["-output"]     = "output"

flag_defs["-s"]            = "small"
flag_defs["--small"]       = "small"
flag_defs["-l"]            = "large"
flag_defs["--large"]       = "large"
flag_defs["-r"]            = "rounded"
flag_defs["--rounded"]     = "rounded"
flag_defs["-p"]            = "oneperpage"
flag_defs["--oneperpage"]  = "oneperpage"
flag_defs["-h"]            = "help"
flag_defs["--help"]        = "help"


args = parse_args(arg_defs, flag_defs)
card_geometry = get_card_geometry(2.0,2.0, !(args["rounded"]).nil?, !(args["oneperpage"]).nil? )
if args.has_key? "large"
  card_geometry = get_card_geometry(2.74,3.74, (not (args["rounded"]).nil?), (not (args["oneperpage"]).nil? ))
end

if args.has_key? "help" or args.length == 0 or ( (not args.has_key? "white") and (not args.has_key? "black") and (not args.has_key? "dir") )
  print_help
elsif args.has_key? "dir"
  render_cards args["dir"], "white.txt", "black.txt", "icon.png", "cards.pdf", false, true, true, card_geometry, "", "", false
else
  render_cards nil, args["white"], args["black"], args["icon"], args["output"], true, false, false, card_geometry, "", "", false
end

exit


