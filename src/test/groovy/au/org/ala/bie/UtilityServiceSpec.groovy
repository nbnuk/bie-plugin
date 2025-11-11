package au.org.ala.bie


import spock.lang.Specification

/**
 * See the API for {@link grails.test.mixin.services.ServiceUnitTestMixin} for usage instructions
 */
class UtilityServiceSpec extends Specification {
    void "test encoding with quotes and spaces"() {
        when:
        def encoded = UtilityService.encodeQuerystringValues('fq=listMembership_m_s:"INNS of Interest to Wales June 2022"')
        then:
        encoded == "fq=listMembership_m_s%3A%22INNS+of+Interest+to+Wales+June+2022%22"
    }

    void "test encoding with parenthesis"() {
        when:
        def encoded = UtilityService.encodeQuerystringValues('fq=(-idxtype:REGIONFEATURED AND -idxtype:LOCALITY)')
        then:
        encoded == "fq=%28-idxtype%3AREGIONFEATURED+AND+-idxtype%3ALOCALITY%29"
    }

    void "test encoding with multiple fq"() {
        when:
        def encoded = UtilityService.encodeQuerystringValues('fq=-idxtype:REGIONFEATURED&fq=-idxtype:LOCALITY')
        then:
        encoded == "fq=-idxtype%3AREGIONFEATURED&fq=-idxtype%3ALOCALITY"
    }

    void "test removal of empty segments"() {
        when:
        def encoded = UtilityService.encodeQuerystringValues('&fq=-idxtype:LOCALITY&')
        then:
        encoded == "fq=-idxtype%3ALOCALITY"
    }
}
