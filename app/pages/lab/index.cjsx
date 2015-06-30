React = require 'react'
{Link, Navigation} = require 'react-router'
PromiseRenderer = require '../../components/promise-renderer'
LoadingIndicator = require '../../components/loading-indicator'
apiClient = require '../../api/client'
counterpart = require 'counterpart'
LandingPage = require './landing-page'

ChangeListener = require '../../components/change-listener'
auth = require '../../api/auth'

module.exports = React.createClass
  displayName: 'LabIndex'

  mixins: [Navigation]

  getDefaultProps: ->
    query:
      page: 1

  getInitialState: ->
    loading: false
    projects: []
    creationError: null
    creationInProgress: false

  componentDidMount: ->
    @fetchProjects @props.query.page

  componentWillReceiveProps: (nextProps) ->
    unless nextProps.query.page is @props.query.page
      @fetchProjects nextProps.query.page

  fetchProjects: (page = 1) ->
    @setState loading: true

    if auth.current?
      query =
        current_user_roles: ['owner', 'collaborator']
        page: page

      apiClient.type('projects').get(query).then (projects) =>
        @setState
          loading: false
          projects: projects

    else
      @setState
        loading: false
        projects: []

  render: ->
    if @state.loading or auth.pending
      <p>Loading</p>
    else if auth.current? and @state.projects.length isnt 0
        <div className="content-container">
          <div>
            <table>
              <tbody>
                {for project in @state.projects then do (project) =>
                  <tr key={project.id}>
                    <td>{project.display_name}</td>
                    <td><Link to="edit-project-details" params={projectID: project.id} className="minor-button"><i className="fa fa-pencil"></i> Edit</Link></td>
                    <td>
                      <PromiseRenderer promise={project.get 'owner'}>{(owner) =>
                        <Link to="project-home" params={owner: owner.login, name: project.slug} className="minor-button"><i className="fa fa-hand-o-right"></i> View</Link>
                      }</PromiseRenderer>
                    </td>
                  </tr>}
              </tbody>
            </table>

            {meta = @state.projects[0]?.getMeta()
            if meta? and meta.page_count isnt 1
              <nav className="pagination">
                <label>
                  Page
                  {' '}
                  <select value={@state.page} onChange={@handlePageChange}>
                    {for page in [1..meta.page_count]
                      <option key={page} value={page}>{page}</option>}
                  </select>
                  {' '}
                  of {meta.page_count}
                </label>
              </nav>}
          </div>
          <br />
          <button className="standard-button" disabled={@state.creationInProgress} onClick={@createNewProject.bind this, auth.current}>
            Create a new project{' '}
            <LoadingIndicator off={not @state.creationInProgress} />
          </button>&nbsp;
          <Link className="standard-button" to="lab-policies">Project building policies</Link>&nbsp;
          <a className="standard-button" href="https://docs.google.com/document/d/1EpiOJFMGFzIq34NXkRvsO8-Hixl4MzxvwPm0_aiF9xo/edit#heading=h.gjdgxs" target="_blank">How to build a project</a>
          {if @state.creationError?
            <p className="form-help error">{@state.creationError.message}</p>}
        </div>
      else
        <LandingPage user={auth.current} parentIndex={this} />

  handlePageChange: (e) ->
    @setState page: e.target.value

  createNewProject: (user) ->
    project = apiClient.type('projects').create
      display_name: "Untitled project #{new Date().toISOString()}"
      description: 'Description of project'
      primary_language: counterpart.getLocale()
      private: true

    @setState
      creationError: null
      creationInProgress: true

    project.save()
      .catch (error) =>
        @setState creationError: error
      .then (project) =>
        # TODO: user.uncacheLink 'project'
        @setState creationInProgress: false
        @transitionTo 'edit-project-details', projectID: project.id
