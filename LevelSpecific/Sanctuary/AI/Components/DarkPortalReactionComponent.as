class UDarkPortalReactionComponent : UActorComponent
{
	AHazeActor HazeOwner;
	UDarkPortalReactionTeam ReactionTeam;
	int MaxGrabbed = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		HazeOwner = Cast<AHazeActor>(Owner);
		ReactionTeam = Cast<UDarkPortalReactionTeam>(HazeOwner.JoinTeam(DarkPortalReactionTags::DarkPortalReactionTeam, UDarkPortalReactionTeam));

		auto DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);
		DarkPortalComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		DarkPortalComp.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION()
	private void OnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ReactionTeam.Release(HazeOwner);
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		ReactionTeam.Grab(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		HazeOwner.LeaveTeam(DarkPortalReactionTags::DarkPortalReactionTeam);
	}
}

namespace DarkPortalReactionTags
{
	const FName DarkPortalReactionTeam = n"DarkPortalReactionTeam";
}