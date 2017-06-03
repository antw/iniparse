require 'spec_helper'

describe "IniParse" do
  describe 'openttd.ini fixture' do
    before(:all) do
      @fixture = fixture('openttd.ini')
    end

    it 'should parse without any errors' do
      expect { IniParse.parse(@fixture) }.not_to raise_error
    end

    it 'should have the correct sections' do
      expect(IniParse.parse(fixture('openttd.ini')).lines.keys).to eq([
        'misc', 'music', 'difficulty', 'game_creation', 'vehicle',
        'construction', 'station', 'economy', 'pf', 'order', 'gui', 'ai',
        'locale', 'network', 'currency', 'servers', 'bans', 'news_display',
        'version', 'preset-J', 'newgrf', 'newgrf-static'
      ])
    end

    it 'should have the correct options' do
      # Test the keys from one section.
      doc     = IniParse.parse(@fixture)
      section = doc['misc']

      expect(section.lines.keys).to eq([
        'display_opt', 'news_ticker_sound', 'fullscreen', 'language',
        'resolution', 'screenshot_format', 'savegame_format',
        'rightclick_emulate', 'small_font', 'medium_font', 'large_font',
        'small_size', 'medium_size', 'large_size', 'small_aa', 'medium_aa',
        'large_aa', 'sprite_cache_size', 'player_face',
        'transparency_options', 'transparency_locks', 'invisibility_options',
        'keyboard', 'keyboard_caps'
      ])

      # Test some of the options.
      expect(section['display_opt']).to eq('SHOW_TOWN_NAMES|SHOW_STATION_NAMES|SHOW_SIGNS|FULL_ANIMATION|FULL_DETAIL|WAYPOINTS')
      expect(section['news_ticker_sound']).to be_falsey
      expect(section['language']).to eq('english_US.lng')
      expect(section['resolution']).to eq('1680,936')
      expect(section['large_size']).to eq(16)

      # Test some other options.
      expect(doc['currency']['suffix']).to eq('" credits"')
      expect(doc['news_display']['production_nobody']).to eq('summarized')
      expect(doc['version']['version_number']).to eq('070039B0')

      expect(doc['preset-J']['gcf/1_other/BlackCC/mauvetoblackw.grf']).to be_nil
      expect(doc['preset-J']['gcf/1_other/OpenGFX/OpenGFX_-_newFaces_v0.1.grf']).to be_nil
    end

    it 'should be identical to the original when calling #to_ini' do
      expect(IniParse.parse(@fixture).to_ini).to eq(@fixture)
    end
  end

  describe 'race07.ini fixture' do
    before(:all) do
      @fixture = fixture('race07.ini')
    end

    it 'should parse without any errors' do
      expect { IniParse.parse(@fixture) }.not_to raise_error
    end

    it 'should have the correct sections' do
      expect(IniParse.parse(fixture('race07.ini')).lines.keys).to eq([
        'Header', 'Race', 'Slot010', 'Slot016', 'Slot013', 'Slot018',
        'Slot002', 'END'
      ])
    end

    it 'should have the correct options' do
      # Test the keys from one section.
      doc     = IniParse.parse(@fixture)
      section = doc['Slot010']

      expect(section.lines.keys).to eq([
        'Driver', 'SteamUser', 'SteamId', 'Vehicle', 'Team', 'QualTime',
        'Laps', 'Lap', 'LapDistanceTravelled', 'BestLap', 'RaceTime'
      ])

      # Test some of the options.
      expect(section['Driver']).to eq('Mark Voss')
      expect(section['SteamUser']).to eq('mvoss')
      expect(section['SteamId']).to eq(1865369)
      expect(section['Vehicle']).to eq('Chevrolet Lacetti 2007')
      expect(section['Team']).to eq('TEMPLATE_TEAM')
      expect(section['QualTime']).to eq('1:37.839')
      expect(section['Laps']).to eq(13)
      expect(section['LapDistanceTravelled']).to eq(3857.750244)
      expect(section['BestLap']).to eq('1:38.031')
      expect(section['RaceTime']).to eq('0:21:38.988')

      expect(section['Lap']).to eq([
        '(0, -1.000, 1:48.697)',   '(1, 89.397, 1:39.455)',
        '(2, 198.095, 1:38.060)',  '(3, 297.550, 1:38.632)',
        '(4, 395.610, 1:38.031)',  '(5, 494.242, 1:39.562)',
        '(6, 592.273, 1:39.950)',  '(7, 691.835, 1:38.366)',
        '(8, 791.785, 1:39.889)',  '(9, 890.151, 1:39.420)',
        '(10, 990.040, 1:39.401)', '(11, 1089.460, 1:39.506)',
        '(12, 1188.862, 1:40.017)'
      ])

      expect(doc['Header']['Version']).to eq('1.1.1.14')
      expect(doc['Header']['TimeString']).to eq('2008/09/13 23:26:32')
      expect(doc['Header']['Aids']).to eq('0,0,0,0,0,1,1,0,0')

      expect(doc['Race']['AIDB']).to eq('GameData\Locations\Anderstorp_2007\2007_ANDERSTORP.AIW')
      expect(doc['Race']['Race Length']).to eq(0.1)
    end

    it 'should be identical to the original when calling #to_ini' do
      pending('awaiting presevation (or lack) of whitespace around =')
      expect(IniParse.parse(@fixture).to_ini).to eq(@fixture)
    end
  end

  describe 'smb.ini fixture' do
    before(:all) do
      @fixture = fixture('smb.ini')
    end

    it 'should parse without any errors' do
      expect { IniParse.parse(@fixture) }.not_to raise_error
    end

    it 'should have the correct sections' do
      expect(IniParse.parse(@fixture).lines.keys).to eq([
        'global', 'printers'
      ])
    end

    it 'should have the correct options' do
      # Test the keys from one section.
      doc     = IniParse.parse(@fixture)
      section = doc['global']

      expect(section.lines.keys).to eq([
        'debug pid', 'log level', 'server string', 'printcap name',
        'printing', 'encrypt passwords', 'use spnego', 'passdb backend',
        'idmap domains', 'idmap config default: default',
        'idmap config default: backend', 'idmap alloc backend',
        'idmap negative cache time', 'map to guest', 'guest account',
        'unix charset', 'display charset', 'dos charset', 'vfs objects',
        'os level', 'domain master', 'max xmit', 'use sendfile',
        'stream support', 'ea support', 'darwin_streams:brlm',
        'enable core files', 'usershare max shares', 'usershare path',
        'usershare owner only', 'usershare allow guests',
        'usershare allow full config', 'com.apple:filter shares by access',
        'obey pam restrictions', 'acl check permissions',
        'name resolve order', 'include'
      ])

      expect(section['display charset']).to eq('UTF-8-MAC')
      expect(section['vfs objects']).to eq('darwinacl,darwin_streams')
      expect(section['usershare path']).to eq('/var/samba/shares')
    end

    it 'should be identical to the original when calling #to_ini' do
      expect(IniParse.parse(@fixture).to_ini).to eq(@fixture)
    end
  end

  describe 'authconfig.ini fixture' do
    before(:all) do
      @fixture = fixture('authconfig.ini')
    end

    it 'should be identical to the original when calling #to_ini' do
      expect(IniParse.parse(@fixture).to_ini).to eq(@fixture)
    end
  end

  describe 'option before section fixture' do
    before(:all) do
      @fixture = fixture(:option_before_section)
    end

    it 'should be identical to the original when calling #to_ini' do
      expect(IniParse.parse(@fixture).to_ini).to eq(@fixture)
    end
  end

  describe 'anonymous-order.ini fixture' do
    # https://github.com/antw/iniparse/issues/17
    let(:raw) { fixture(:anon_section_with_comments) }

    it 'should be identical to the original when calling #to_ini' do
      expect(IniParse.parse(raw).to_ini).to eq(raw)
    end
  end

  describe 'multiline.ini fixture' do
    # https://github.com/antw/iniparse/issues/6
    before(:all) do
      @fixture = fixture('multiline.ini')
      @result = fixture(:multiline_result)
    end

    it 'should be identical to expected result when calling #to_ini' do
      expect(IniParse.parse(@fixture).to_ini).to eq(@result)
    end
  end
end
