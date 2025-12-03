
class UPerchEnterByZoneComponent : UHazeMovablePlayerTriggerComponent
{
	default Shape = FHazeShapeSettings::MakeSphere(500.0);
	default bVisible = false;
	
	UPROPERTY(EditAnywhere)
	bool bUseNameToFindComponent = false;
	UPROPERTY(EditAnywhere)
	FName NameToUse;

	UPerchPointComponent OwningPerchPoint;

	FVector PreviousPerchWorldLocation;
	FVector PreviousPerchWorldVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bUseNameToFindComponent)
		{
			OwningPerchPoint = Cast<UPerchPointComponent>(AttachParent);
			if (OwningPerchPoint == nullptr)
				OwningPerchPoint = UPerchPointComponent::Get(Owner);
		}
		else
		{
			OwningPerchPoint = UPerchPointComponent::Get(Owner, NameToUse);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter OtherActor)
	{
		auto PlayerPerchComp = UPlayerPerchComponent::Get(OtherActor);
		if(PlayerPerchComp == nullptr || OwningPerchPoint == nullptr)
			return;

		PlayerPerchComp.QueryZones.RemoveSwap(this);

		auto AirDashComp = UPlayerAirDashComponent::Get(OtherActor);
		AirDashComp.RemoveAutoTarget(OwningPerchPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter OtherActor)
	{
		auto PlayerPerchComp = UPlayerPerchComponent::Get(OtherActor);
		if(PlayerPerchComp == nullptr || OwningPerchPoint == nullptr)
			return;

		if(!OwningPerchPoint.bAllowPerch)
			return;

		if(!OtherActor.IsSelectedBy(OwningPerchPoint.UsableByPlayers))
			return;

		PlayerPerchComp.QueryZones.Add(this);
		PreviousPerchWorldLocation = OwningPerchPoint.GetLocationForVelocity();
		PreviousPerchWorldVelocity = FVector::ZeroVector;

		// Add an auto-target for airdashing to the perch point
		if (!OwningPerchPoint.bHasConnectedSpline)
		{
			auto AirDashComp = UPlayerAirDashComponent::Get(OtherActor);

			FAirDashAutoTarget AutoTarget;
			AutoTarget.Component = OwningPerchPoint;
			AutoTarget.bCheckHeightDifference = true;
			AutoTarget.MinHeightDifference = -10.0;
			AutoTarget.MaxHeightDifference = 220.0;
			AutoTarget.bCheckInputAngle = true;
			AutoTarget.MaxInputAngle = 20.0;
			AutoTarget.MaxShortening = 200.0;
			AutoTarget.ShortenExtraMargin = 50.0;
			AutoTarget.bCheckFlatDistance = true;
			AutoTarget.MinFlatDistance = 30.0;
			AutoTarget.MaxFlatDistance = 400.0;

			AirDashComp.AddAutoTarget(AutoTarget);
		}
	}

	//Check if player world up matches relative up vector of Owning PerchPoint
	bool ValidatePlayerWorldUp(AHazePlayerCharacter Player) const
	{
		if(OwningPerchPoint.WorldRotation.UpVector.DotProduct(Player.MovementWorldUp) < 0.0)
			return false;

		float Angle = OwningPerchPoint.WorldRotation.UpVector.GetAngleDegreesTo(Player.MovementWorldUp);
		if(Angle > OwningPerchPoint.UpVectorCutOffAngle)
			return false;
		else
			return true;
	}
}