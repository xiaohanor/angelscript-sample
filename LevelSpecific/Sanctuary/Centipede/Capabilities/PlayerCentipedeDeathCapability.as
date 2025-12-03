// Active for as long as centipede is dead
class UPlayerCentipedeDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastDemotable;

	default DebugCategory = CentipedeTags::Centipede;

	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerCentipedeComponent PlayerCentipedeComponent;
	UPlayerCentipedeSwingComponent PlayerCentipedeSwingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Owner);
		PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		PlayerCentipedeSwingComponent = UPlayerCentipedeSwingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerCentipedeComponent.IsCentipedeDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PlayerCentipedeComponent.IsCentipedeDead())
			return true;

		return false;
	}

	// Clean systems
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CentipedeBiteComponent.StopBiting();

		PlayerCentipedeSwingComponent.Reset();
	}
}