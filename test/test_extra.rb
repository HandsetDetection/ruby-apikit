require 'minitest/autorun'
require 'handset_detection'

class ExtraTest < Minitest::Test 

  def test_compare_platform_versions_a
    extra = Extra.new
    result = extra.compare_platform_versions '9.0.1', '9.1'
    assert result <= -1
  end

  def test_compare_platform_versions_b
    extra = Extra.new
    result = extra.compare_platform_versions '9.0.1', '9.0.1'
    assert_equal result, 0
  end

  def test_compare_platform_versions_c
    extra = Extra.new
    result = extra.compare_platform_versions '9.1', '9.0.1'
    assert result >= 1
  end

  def test_compare_platform_versions_d
    extra = Extra.new
    result = extra.compare_platform_versions '4.2.1', '9.1'
    assert result <= -1
  end

  def test_compare_platform_versions_e
    extra = Extra.new
    result = extra.compare_platform_versions '4.2.1', '4.2.2'
    assert result <= -1
  end

  def test_compare_platform_versions_f
    extra = Extra.new
    result = extra.compare_platform_versions '4.2.1', '4.2.12'
    assert result <= -1
  end

  def test_compare_platform_versions_g
    extra = Extra.new
    result = extra.compare_platform_versions '4.1.1', '4.2.1'
    assert result <= -1
  end

  def test_compare_platform_versions_h
    extra = Extra.new
    result = extra.compare_platform_versions '4.0.21', '40.21'
    assert result <= -1
  end

  def test_compare_platform_versions_i
    extra = Extra.new
    result = extra.compare_platform_versions '4.1.1', '411'
    assert result <= -1
  end

  def test_compare_platform_versions_j
    extra = Extra.new
    result = extra.compare_platform_versions '411', '4.1.1'
    assert result >= 1
  end

  def test_compare_platform_versions_k
    extra = Extra.new
    result = extra.compare_platform_versions 'Q7.1', 'Q7.2'
    assert result <= 1
  end

  def test_compare_platform_versions_l
    extra = Extra.new
    result = extra.compare_platform_versions 'Q5SK', 'Q7SK'
    assert result <= 1
  end
end
