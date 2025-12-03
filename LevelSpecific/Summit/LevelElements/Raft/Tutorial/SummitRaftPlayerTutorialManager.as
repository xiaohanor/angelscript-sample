class ASummitRaftPlayerTutorialManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerSheets.Add(SummitRaftPlayerTutorialSheet);
	default RequestComp.PlayerSheets_Mio.Add(SummitMioFakeFlyingSheet);
};

asset SummitRaftPlayerTutorialSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitRaftPlayerDragonTutorialCapability);
	Components.Add(USummitRaftPlayerDragonTutorialComponent);
}

asset SummitMioFakeFlyingSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitMioFakeFlyingCapability);
	Components.Add(USummitMioFakeFlyingComponent);
}