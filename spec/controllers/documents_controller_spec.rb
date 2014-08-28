require 'spec_helper'

describe DocumentsController do
  let(:user) { @user }
  let(:document) { @document }
  let(:valid_attributes) { {
      'title' => 'MyString',
      'body' => 'MyText',
      'user_id' => "#{user.id}"
  } }
  let(:valid_session) { {} }
  before(:each) do
    @user = FactoryGirl.create(:user)
    request.env['warden'].stub :authenticate! => user
    controller.stub :current_user => user
    @document = FactoryGirl.create(:document)
  end

  it 'should raise an error if no project was found' do
    expect {
      get :show, { id: @document.id, project_id: @document.project.id + 3 }, valid_session
    }.to raise_error ActiveRecord::RecordNotFound
  end

  # Bryan: Deprecated path
  #describe 'GET index' do
  #  before(:each) { get :index, { project_id: document.friendly_id }, valid_session }
  #
  #  it 'assigns all documents as @documents' do
  #    assigns(:documents).should eq([document])
  #  end
  #
  #  it 'renders the index template' do
  #    expect(response).to render_template 'index'
  #  end
  #end

  describe 'GET show' do

    context 'with a single project' do
      before(:each) do
        get :show, {:id => document.to_param, project_id: document.project.friendly_id}, valid_session
      end

      it 'assigns the requested document as @document' do
        assigns(:document).should eq(document)
      end

      it 'renders the show template' do
        expect(response).to render_template 'show'
      end
    end

    context 'with more than one project' do
      before(:each) do
        @document_2 = FactoryGirl.create(:document)
      end

      it 'should not mistakenly render the document under the wrong project' do
        expect {
          get :show, { id: document.to_param, project_id: @document_2.project.friendly_id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'UPDATE show' do
    context 'changes document parent' do
      let(:categories) do 
        [
        FactoryGirl.create(:document, id: 555, project_id: document.project_id, parent_id: nil, title: "Title-1"),
        FactoryGirl.create(:document, id: 556, project_id: document.project_id, parent_id: nil, title: "Title-2")
        ]
      end
      let(:params) { {:id => categories.first.to_param, project_id: document.project.friendly_id, categories: 'true'} }

      it 'assigns the available categories to @categories' do
        get :show, params.merge({id: document.to_param})
        expect(assigns(:categories)).to  match_array categories
      end

      it 'calls the get_doc_categories function' do
        expect(controller).to receive(:get_doc_categories)
        get :show, params
      end

      it 'renders the categories partial' do
        get :show, params
        expect(response).to render_template(:partial => '_categories')
      end

      it 'calls change_document_parent with the right param' do
        expect(controller).to receive(:change_document_parent).with("555")
        get :update, params.merge({ new_parent_id:'555' })
      end

      it 'changes the document parent_id' do
        get :update, params.merge({ new_parent_id:'556' })
        categories.first.parent_id = 556
        expect(assigns(:document)).to eq(categories.first)
      end

      it 'assigns flash message after changing parent_id' do
        get :update, params.merge({ new_parent_id:'556' })
        expect(flash[:notice]).to eq("You have successfully moved Title-1 to the Title-2 section.")
      end
    end
  end

  describe 'GET new' do
    before(:each) { get :new, {project_id: document.project.friendly_id}, valid_session }

    it 'assigns a new document as @document' do
      assigns(:document).should be_a_new(Document)
    end

    it 'renders the new template' do
      expect(response).to render_template 'new'
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Document' do
        expect {
          post :create, {project_id: document.project.friendly_id, :document => valid_attributes}
        }.to change(Document, :count).by 1
      end

      it 'assigns a newly created document as @document' do
        post :create, {project_id: document.project.friendly_id, :document => valid_attributes}, valid_session
        assigns(:document).should be_a(Document)
        assigns(:document).should be_persisted
      end

      it 'redirects to the created document' do
        post :create, {project_id: document.project.friendly_id, :document => valid_attributes}, valid_session
        expect(response).to redirect_to project_document_path(Document.last.project, Document.last)
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved document as @document' do
        # Trigger the behavior that occurs when invalid params are submitted
        Document.any_instance.stub(:save).and_return(false)
        post :create, {project_id: document.project.friendly_id, :document => { title: 'invalid value' }}, valid_session
        assigns(:document).should be_a_new(Document)
        assigns(:document).should_not be_persisted
      end

      it 're-renders the new template' do
        # Trigger the behavior that occurs when invalid params are submitted
        Document.any_instance.stub(:save).and_return(false)
        post :create, {project_id: document.project.friendly_id, :document => { title: 'invalid value' }}, valid_session
        expect(response).to render_template 'new'
      end
    end
  end

  describe 'DELETE destroy' do
    before(:each) { @document = FactoryGirl.create(:document) }

    it 'destroys the requested document' do
      expect {
        delete :destroy, {:id => @document.to_param, project_id: @document.project.friendly_id}, valid_session
      }.to change(Document, :count).by(-1)
    end

    it 'redirects to the documents list' do
      id = @document.project.id
      delete :destroy, {:id => @document.to_param, project_id: @document.project.friendly_id}, valid_session
      response.should redirect_to(project_documents_path(id))
    end
  end
end
