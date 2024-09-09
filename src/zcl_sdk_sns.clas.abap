class ZCL_SDK_SNS definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !I_PROFILE type /AWS1/RT_PROFILE_ID
      !I_SNSARN type STRING .
  methods SEND_MESSAGE
    importing
      !I_TEXT type STRING .
protected section.
private section.

  data GV_PROFILE type /AWS1/RT_PROFILE_ID .
  data GV_SNSARN type STRING .
ENDCLASS.



CLASS ZCL_SDK_SNS IMPLEMENTATION.


  method CONSTRUCTOR.
    gv_profile = i_profile.
    gv_snsarn = i_snsarn.
  endmethod.


  METHOD: SEND_MESSAGE.

     TRY.
        "Create a ABAP SDK session for SNS"
        DATA(lo_session) = /aws1/cl_rt_session_aws=>create( gv_profile ).
        DATA(lo_sns) = /aws1/cl_sns_factory=>create( lo_session ).

        "publish a message to SNS topic"
        DATA(lo_result) = lo_sns->publish(
          iv_topicarn = gv_snsarn
          iv_message = i_text

        ).
        WRITE:/ 'Message published to SNS topic.'.

     CATCH /aws1/cx_snsnotfoundexception.
        WRITE:/ 'Topic does not exist.'.
     CATCH /aws1/cx_rt_service_generic.
        WRITE:/ 'Generic Service call error'.
     CATCH /aws1/cx_rt_no_auth_generic.
        WRITE:/ 'Generic lack of authorization'.
     CATCH /aws1/cx_rt_technical_generic.
        WRITE:/ 'Technical errors'.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
