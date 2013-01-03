class EmailFrontPageController < ApplicationController
  layout 'email_front_page'

  def approve_mock_up
    @mock_up = MockUp.find(params[:id])

    # Get last revision.
    revision = @mock_up.mock_up_revisions.find(:first, :order => "created_at DESC")

    if params[:checksum] != revision.checksum
      redirect_to :action => "mock_up_access_not_granted"
      return
    end

    if revision.accepted
      redirect_to :action => "mock_up_already_accepted"
      return
    end

    @lang_id = @mock_up.bulk_order.language_id

    @files = revision.mock_up_revision_files

    @states = [["", 0],
      [I18n.t(:email_front_page_approve_mock_up_approve, :locale => Language.find(@lang_id).shortname), MockUpState.find_by_str_id("accepted").id],
      [I18n.t(:email_front_page_approve_mock_up_decline, :locale => Language.find(@lang_id).shortname), MockUpState.find_by_str_id("assigned").id]]

    @title = I18n.t(:email_front_page_approve_mock_up_title, :locale => Language.find(@lang_id).shortname)
  end

  def confirm_mock_up
    @mock_up = MockUp.find(params[:id])

    # Get last revision.
    revision = @mock_up.mock_up_revisions.find(:first, :order => "created_at DESC")

    if params[:checksum] != revision.checksum
      redirect_to :action => "mock_up_access_not_granted"
      return
    end

    state = params[:revision][:state].to_i
    comment = params[:revision][:approval_comment].to_s

    if state > 0 && ! (state == MockUpState.find_by_str_id("assigned").id && comment == "")
      # Valid
      # Save the revision:
      revision.accepted = state == MockUpState.find_by_str_id("accepted").id
      revision.approval_comment = comment
      revision.save

      # Modify mock up state:
      @mock_up.update_attributes(:mock_up_state_id => state)

      # Set bulk order state to SAMPLE if the client accepted
      if revision.accepted
        @mock_up.bulk_order.bulk_orders_state_id = BulkOrdersState.find_by_str_id("sample").id
        @mock_up.bulk_order.save
      end
    else
      # Invalid
      flash[:error] = t(:email_front_page_approve_mock_up_error)
      redirect_to :back
    end

    @title = I18n.t(:email_front_page_approve_mock_up_title, :locale => Language.find(@mock_up.bulk_order.language_id).shortname)
  end

  def mock_up_already_accepted
    @title = I18n.t(:email_front_page_approve_mock_up_title, :locale => Language.find(@lang_id).shortname)
  end

  def mock_up_access_not_granted
    @title = I18n.t(:email_front_page_approve_mock_up_title, :locale => Language.find(@lang_id).shortname)
  end
end