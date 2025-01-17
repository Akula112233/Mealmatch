import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'main.dart';
import 'state.dart';

class DonatorDonationsNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context, body: NewDonationForm(), title: 'New Donation');
  }
}

class NewDonationForm extends StatefulWidget {
  @override
  _NewDonationFormState createState() => _NewDonationFormState();
}

class _NewDonationFormState extends State<NewDonationForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Enter Information Below',
        buildMyFormListView(_formKey, [
          buildMyStandardNumberFormField('numMeals', 'Number of meals'),
          buildMyStandardTextFormField('dateAndTime', 'Date and time range'),
          buildMyStandardTextFormField('description', 'Food description'),
          buildMyStandardTextFormField('streetAddress', 'Address'),
          buildMyStandardButton('Submit new donation', () {
            if (_formKey.currentState.saveAndValidate()) {
              var value = _formKey.currentState.value;
              doSnackbarOperation(
                  context,
                  'Adding new donation...',
                  'Added new donation!',
                  Api.newDonation(Donation()
                    ..formRead(value)
                    ..donatorId = provideAuthenticationModel(context).uid
                    ..numMealsRequested = 0),
                  MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
            }
          })
        ]));
  }
}

class DonatorDonationsViewPage extends StatelessWidget {
  const DonatorDonationsViewPage(this.donationAndInterests);

  final DonationAndInterests donationAndInterests;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: ViewDonation(donationAndInterests),
        title: 'Donation');
  }
}

class ViewDonation extends StatefulWidget {
  ViewDonation(this.initialValue);

  final DonationAndInterests initialValue;

  @override
  _ViewDonationState createState() => _ViewDonationState();
}

class _ViewDonationState extends State<ViewDonation> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScrollableGradientBoxWithBack(
        context,
        'Info',
        buildMyFormListView(
            _formKey,
            [
              buildMyStandardNumberFormField('numMeals', 'Number of meals'),
              buildMyStandardTextFormField('dateAndTime', 'Date and time'),
              buildMyStandardTextFormField('description', 'Description'),
              buildMyStandardTextFormField('streetAddress', 'Address'),
              buildMyStandardButton('Save', () {
                if (_formKey.currentState.saveAndValidate()) {
                  var value = _formKey.currentState.value;
                  doSnackbarOperation(
                      context,
                      'Saving...',
                      'Saved!',
                      Api.editDonation(
                          widget.initialValue.donation..formRead(value)),
                      MySnackbarOperationBehavior.POP_ONE_AND_REFRESH);
                }
              }),
              buildMyStandardButton('Delete', () {
                showDialog(
                    context: context,
                    builder: (context) =>
                        AlertDialog(title: Text('Really delete?'), actions: [
                          FlatButton(
                              child: Text('Yes'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                doSnackbarOperation(
                                    context,
                                    'Deleting donation...',
                                    'Donation deleted!',
                                    Api.deleteDonation(
                                        widget.initialValue.donation),
                                    MySnackbarOperationBehavior
                                        .POP_ONE_AND_REFRESH);
                              }),
                          FlatButton(
                              child: Text('No'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              })
                        ]));
              }),
              // TODO here you can show the interests (which are already loaded!!) and you can go to /donator/donations/interests/view to chat/change status
              for (final interest in widget.initialValue.interests)
                FutureBuilder<Requester>(
                    future: Api.getRequester(interest.requesterId),
                    builder: (context, requesterSnapshot) {
                      if (requesterSnapshot.connectionState ==
                          ConnectionState.done) {
                        return buildMyStandardBlackBox(
                            title:
                                "${requesterSnapshot.data.name} Date: ${interest.requestedPickupDateAndTime}",
                            content:
                                "Address: ${interest.requestedPickupLocation}\nNumber of Adult Meals: ${interest.numAdultMeals}\nNumber of Child Meals: ${interest.numChildMeals}",
                            moreInfo: () => NavigationUtil.navigate(
                                context,
                                '/donator/donations/interests/view',
                                DonationInterestAndRequester(
                                    widget.initialValue.donation,
                                    interest,
                                    requesterSnapshot.data)));
                      }
                      // TODO this should be an actual loading spinner
                      return Container();
                    })
            ],
            initialValue: widget.initialValue.donation.formWrite()));
  }
}

class DonatorDonationsInterestsViewPage extends StatelessWidget {
  const DonatorDonationsInterestsViewPage(this.initialValue);

  final DonationInterestAndRequester initialValue;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: DonationsInterestView(initialValue),
        title: 'Interest');
  }
}

class DonationsInterestView extends StatelessWidget {
  const DonationsInterestView(this.initialValue);

  final DonationInterestAndRequester initialValue;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<DonatorViewInterestInfo>(
              api: Api.getDonatorViewInterestInfo(uid, initialValue),
              child: (context, x) => Column(children: [
                    StatusInterface(
                        initialStatus: x.interest.status,
                        onStatusChanged: (newStatus) => doSnackbarOperation(
                            context,
                            'Changing status...',
                            'Status changed!',
                            Api.editInterest(x.interest..status = newStatus))),
                    Expanded(
                        child: ChatInterface(x.messages, (message) async {
                      await doSnackbarOperation(
                          context,
                          'Sending message...',
                          'Message sent!',
                          Api.newChatMessage(ChatMessage()
                            ..timestamp = DateTime.now()
                            ..speakerUid = uid
                            ..donatorId = uid
                            ..requesterId = x.requester.id
                            ..interestId = x.interest.id
                            ..message = message));
                      refresh();
                    }))
                  ])),
    );
  }
}

class DonatorPublicRequestsViewPage extends StatelessWidget {
  const DonatorPublicRequestsViewPage(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    return buildMyStandardScaffold(
        context: context,
        body: ViewPublicRequest(publicRequest),
        title: 'Request');
  }
}

class ViewPublicRequest extends StatelessWidget {
  const ViewPublicRequest(this.publicRequest);

  final PublicRequest publicRequest;

  @override
  Widget build(BuildContext context) {
    final uid = provideAuthenticationModel(context).uid;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<DonatorViewPublicRequestInfo>(
              api: Api.getDonatorViewPublicRequestInfo(publicRequest, uid),
              child: (context, x) => Column(children: [
                    if (x.publicRequest.donatorId != null)
                      StatusInterface(
                          initialStatus: x.publicRequest.status,
                          onStatusChanged: (newStatus) => doSnackbarOperation(
                              context,
                              'Changing status...',
                              'Status changed!',
                              Api.editPublicRequest(
                                  x.publicRequest..status = newStatus))),
                    if (x.publicRequest.donatorId == null)
                      buildMyStandardButton(
                          'Accept Request',
                          () => doSnackbarOperation(
                              context,
                              'Accepting request...',
                              'Request accepted!',
                              Api.editPublicRequest(
                                  x.publicRequest..donatorId = uid),
                              MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)),
                    if (x.publicRequest.donatorId != null)
                      buildMyStandardButton(
                          'Unaccept Request',
                          () => doSnackbarOperation(
                              context,
                              'Unaccepting request...',
                              'Request unaccepted!',
                              Api.editPublicRequest(
                                  x.publicRequest..donatorId = null),
                              MySnackbarOperationBehavior.POP_ONE_AND_REFRESH)),
                    if (x.publicRequest.donatorId != null)
                      Expanded(
                          child: ChatInterface(x.messages, (message) async {
                        await doSnackbarOperation(
                            context,
                            'Sending message...',
                            'Message sent!',
                            Api.newChatMessage(ChatMessage()
                              ..timestamp = DateTime.now()
                              ..speakerUid = uid
                              ..donatorId = uid
                              ..requesterId = x.publicRequest.requesterId
                              ..publicRequestId = x.publicRequest.id
                              ..message = message));
                        refresh();
                      }))
                  ])),
    );
  }
}

class DonatorPublicRequestsDonationsViewPage extends StatelessWidget {
  const DonatorPublicRequestsDonationsViewPage(this.publicRequestAndDonation);

  final PublicRequestAndDonation publicRequestAndDonation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Commit')),
        body: ViewPublicRequestDonation(publicRequestAndDonation));
  }
}

class ViewPublicRequestDonation extends StatelessWidget {
  const ViewPublicRequestDonation(this.publicRequestAndDonation);

  final PublicRequestAndDonation publicRequestAndDonation;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      ...buildViewDonationContent(publicRequestAndDonation.donation),
      buildMyStandardButton('Commit', () async {
        doSnackbarOperation(
            context,
            'Committing to request...',
            'Committed to request!',
            Api.editPublicRequestCommitting(
                publicRequest: publicRequestAndDonation.publicRequest,
                donation: publicRequestAndDonation.donation,
                committer: UserType.DONATOR),
            MySnackbarOperationBehavior.POP_THREE_AND_REFRESH);
      })
    ]);
  }
}

class DonatorChangeUserInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change user info')),
        body: ChangeDonatorInfoForm());
  }
}

class ChangeDonatorInfoForm extends StatefulWidget {
  @override
  _ChangeDonatorInfoFormState createState() => _ChangeDonatorInfoFormState();
}

class _ChangeDonatorInfoFormState extends State<ChangeDonatorInfoForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<Donator>(
        api: Api.getDonator(provideAuthenticationModel(context).uid),
        child: (context, data) {
          final List<Widget> children = [
            ...buildUserFormFields(),
            buildMyStandardTextFormField(
                'restaurantName', 'Name of restaurant'),
            buildMyStandardTextFormField('foodDescription', 'Food description'),
            buildMyNavigationButton(context, 'Change private user info',
                route: '/donator/changeUserInfo/private', arguments: data.id),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(
                    context,
                    'Saving...',
                    'Successfully saved',
                    Api.editDonator(data..formRead(value)),
                    MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

class DonatorChangeUserInfoPrivatePage extends StatelessWidget {
  const DonatorChangeUserInfoPrivatePage(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Change private user info')),
        body: ChangePrivateDonatorInfoForm(id));
  }
}

class ChangePrivateDonatorInfoForm extends StatefulWidget {
  ChangePrivateDonatorInfoForm(this.id);

  final String id;

  @override
  _ChangePrivateDonatorInfoFormState createState() =>
      _ChangePrivateDonatorInfoFormState();
}

class _ChangePrivateDonatorInfoFormState
    extends State<ChangePrivateDonatorInfoForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return buildMyStandardFutureBuilder<PrivateDonator>(
        api: Api.getPrivateDonator(widget.id),
        child: (context, data) {
          final List<Widget> children = [
            ...buildPrivateUserFormFields(),
            buildMyStandardButton('Save', () {
              if (_formKey.currentState.saveAndValidate()) {
                var value = _formKey.currentState.value;
                doSnackbarOperation(
                    context,
                    'Saving...',
                    'Successfully saved',
                    Api.editPrivateDonator(data..formRead(value)),
                    MySnackbarOperationBehavior.POP_ZERO);
              }
            })
          ];
          return buildMyFormListView(_formKey, children,
              initialValue: data.formWrite());
        });
  }
}

class DonatorPendingDonationsAndRequestsView extends StatefulWidget {
  const DonatorPendingDonationsAndRequestsView(this.controller);

  final TabController controller;

  @override
  _DonatorPendingDonationsAndRequestsViewState createState() =>
      _DonatorPendingDonationsAndRequestsViewState();
}

class _DonatorPendingDonationsAndRequestsViewState
    extends State<DonatorPendingDonationsAndRequestsView> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(controller: widget.controller, children: [
      DonatorPendingDonationsList(),
      DonatorPendingRequestsList()
    ]);
  }
}

class DonatorPendingDonationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) =>
          buildMyStandardFutureBuilder<DonatorPendingDonationsListInfo>(
              api: Api.getDonatorPendingDonationsListInfo(
                  provideAuthenticationModel(context).uid),
              child: (context, result) {
                if (result.donations.length == 0) {
                  return buildMyStandardEmptyPlaceholderBox(
                      content: 'No Donations');
                }
                final Map<String, int> numInterestsForDonation = {};
                for (final x in result.donations) {
                  numInterestsForDonation[x.id] = 0;
                }
                for (final x in result.interests) {
                  if (numInterestsForDonation.containsKey(x.donationId)) {
                    ++numInterestsForDonation[x.donationId];
                  }
                }
                return CupertinoScrollbar(
                  child: ListView.builder(
                      itemCount: result.donations.length,
                      padding: EdgeInsets.only(
                          top: 10, bottom: 20, right: 15, left: 15),
                      itemBuilder: (BuildContext context, int index) {
                        final x = result.donations[index];
                        return buildMyStandardBlackBox(
                            title: 'Date: ${x.dateAndTime}',
                            content:
                                'Number of Meals: ${x.numMeals}\nNumber of interests: ${numInterestsForDonation[x.id]}\n',
                            moreInfo: () => NavigationUtil.navigateWithRefresh(
                                originalContext,
                                '/donator/donations/view',
                                refresh,
                                DonationAndInterests(
                                    x,
                                    result.interests
                                        .where((interest) =>
                                            interest.donationId == x.id)
                                        .toList())));
                      }),
                );
              }),
    );
  }
}

class DonatorPendingRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => buildMyStandardFutureBuilder<
              List<PublicRequest>>(
          api: Api.getPublicRequestsByDonatorId(
              provideAuthenticationModel(context).uid),
          child: (context, result) {
            if (result.length == 0) {
              return buildMyStandardEmptyPlaceholderBox(content: 'No Requests');
            }
            return CupertinoScrollbar(
              child: ListView.builder(
                  itemCount: result.length,
                  padding:
                      EdgeInsets.only(top: 10, bottom: 20, right: 15, left: 15),
                  itemBuilder: (BuildContext context, int index) {
                    final x = result[index];
                    return buildMyStandardBlackBox(
                        title: 'Date: ${x.dateAndTime}',
                        content:
                            'Number of Adult Meals: ${x.numMealsAdult}\nNumber of Child Meals: ${x.numMealsChild}\nDietary Restrictions: ${x.dietaryRestrictions}',
                        moreInfo: () => NavigationUtil.navigateWithRefresh(
                            originalContext,
                            '/donator/publicRequests/view',
                            refresh,
                            x));
                  }),
            );
          }),
    );
  }
}

class DonatorRequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final originalContext = context;
    return MyRefreshable(
      builder: (context, refresh) => Column(children: [
        Container(
          padding: EdgeInsets.only(left: 27, right: 5, top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              (Text("Requests Near You",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
              Spacer(),
              Container(
                  child: buildMyNavigationButton(context, "New Donation",
                      route: '/donator/donations/new',
                      textSize: 15,
                      fillWidth: false)),
            ],
          ),
        ),
        buildMyStandardFutureBuilder<List<PublicRequest>>(
            api: Api.getOpenPublicRequests(),
            child: (context, snapshotData) {
              if (snapshotData.length == 0) {
                return buildMyStandardEmptyPlaceholderBox(
                    content: "No requests found nearby.");
              }
              return Expanded(
                child: CupertinoScrollbar(
                  child: ListView.builder(
                      itemCount: snapshotData.length,
                      padding: EdgeInsets.only(
                          top: 10, bottom: 20, right: 15, left: 15),
                      itemBuilder: (BuildContext context, int index) {
                        return FutureBuilder<Requester>(
                            future: Api.getRequester(
                                snapshotData[index].requesterId),
                            builder: (context, requestSnapshot) {
                              if (requestSnapshot.connectionState ==
                                  ConnectionState.done) {
                                final request = snapshotData[index];
                                final requester = requestSnapshot.data;
                                return buildMyStandardBlackBox(
                                    title:
                                        '${requester.name} ${request.dateAndTime}',
                                    content:
                                        'Number of adult meals: ${request.numMealsAdult}\nNumber of child meals: ${request.numMealsChild}\nDietary restrictions: ${request.dietaryRestrictions}\n',
                                    moreInfo: () =>
                                        NavigationUtil.navigateWithRefresh(
                                            originalContext,
                                            '/donator/publicRequests/view',
                                            refresh,
                                            request));
                              }
                              return Container();
                            });
                      }),
                ),
              );
            })
      ]),
    );
  }
}
