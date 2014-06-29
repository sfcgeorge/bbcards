# Bigger, Blacker Cards: A custom card generator for Cards Against Humanity

This fork modifies the script to add bleed area and meet dimension requirements for [this printing company](http://www.printerstudio.com/personalized/custom-playing-cards-gifts.html) who offer poker size cards (same as CAH) for a great price. The original code was a bit of a mess and I certainly haven't helped matters by forking it. Really I should start from scratch, but it works as is so what ya gonna do.

You will need to have ruby, and the latest version of the prawn library installed to use it. It will also try to load the MS core fonts for the web from /usr/share/fonts/truetype/msttcorefonts, which is where they are by default after installing the "ttf-mscorefonts-installer" package on Debian-based distributions of linux.


### Instructions

1. Install Ruby, tested on 2.1 but 1.9.X should work fine too. The script uses Helvetica font, which is included on Macs but I'm not sure what happens on Windows or Linux, perhaps a compatible Helvetica derivative is bundled somewhere.
2. CD into this repo's directory, so the bbcards generator can pick up the icon files.
3. `ruby /path/to/your/clone/of/bbcards/bbcards.rb -l -p -n "Bigger Blacker Cards" -d .`

General instructions for using bbcards.rb on the command line will be displayed if you run bbcards.rb from the command line with no arguments, however I've made some custom modifications to the scipt so they may not be accurate. Reccomended usage is above.


### Licence

This site is not affiliated with nor endorsed by Cards Against Humanity, LLC. Cards Against Humanity is a trademark of Cards Against Humanity LLC. Cards Against Humanity is distributed under a Creative Commons BY-NC-SA 2.0 license - that means you can freely use and modify the game but aren't allowed to make money from it without the permission of Cards Against Humanity LLC.

Also, this should go without saying, but I'm going to say it anyway: Don't use this tool to infringe anyone's intellectual property. Do NOT just plug in the text for existing non-public card packs, that Cards Against Humanity, LLC is selling. That's just not cool. Instead, go to http://www.cardsagainsthumanity.com, and buy their stuff. They made an awesome game, they deserve your money. This tool is for making *your own* cards, not theirs. That's why there's an option to make big 2.5"x3.5" cards -- that way you can print your own custom cards that are the same size as the official, purchased cards, so they can be used together.

While any cards produced by the tool fall under the Creative Commons BY-NC-SA 2.0 license of Cards Against Humanity, the tool itself is released under the GNU GPL v2. It is loosely based on https://github.com/jyruzicka/cahgen, another project to generate cards for Cards Against Humanity using the prawn library.
