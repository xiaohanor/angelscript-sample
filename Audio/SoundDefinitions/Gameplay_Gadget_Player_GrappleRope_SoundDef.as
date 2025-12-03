
UCLASS(Abstract)
class UGameplay_Gadget_Player_GrappleRope_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPlayerSwingComponent SwingComp;
	UPlayerGrappleComponent GrappleComp;
	private EGrapplePointVariations CurrentGrappleType = EGrapplePointVariations::GrapplePoint;

	const float MAX_SWING_VELO_SPEED = 25.0;

	USwingPointComponent GetCurrentSwingPoint() const property
	{
		return SwingComp.Data.ActiveSwingPoint;
	}

	UGrapplePointBaseComponent GetCurrentGrapplePoint() const property
	{
		return GrappleComp.Data.CurrentGrapplePoint;
	}

	private FVector PlayerSwingVelo;
	private FVector CachedPlayerSwingLocation;

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Swinging"))
	bool GetIsSwinging() const
	{
		return SwingComp.IsCurrentlySwinging();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Grappling"))
	bool GetIsGrappling() const
	{
		return GrappleComp.IsGrappleActive();
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SwingComp = UPlayerSwingComponent::Get(PlayerOwner);
		GrappleComp = UPlayerGrappleComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return GetIsGrappling() || GetIsSwinging();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return (!GetIsGrappling() && !GetIsSwinging()) == true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(GetIsSwinging())
		{
			CachedPlayerSwingLocation = PlayerOwner.ActorCenterLocation;
			OnSwingActivated(SwingComp.Data.ActiveSwingPoint);
		}
		else
		{
			CurrentGrappleType = GrappleComp.Data.CurrentGrapplePoint.GrappleType;
			OnGrappleActivated(Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint), GrappleComp.Data.CurrentGrapplePoint.GrappleType);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(GetIsSwinging())
		{
			OnSwingDeactivated();
		}
		else
		{
			OnGrappleDeactivated(CurrentGrappleType);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnSwingActivated(USwingPointComponent SwingPoint) {};

	UFUNCTION(BlueprintEvent)
	void OnSwingDeactivated() {};

	UFUNCTION(BlueprintEvent)
	void OnGrappleActivated(UGrapplePointComponent GrapplePoint, EGrapplePointVariations GrappleType) {};

	UFUNCTION(BlueprintEvent)
	void OnGrappleDeactivated(EGrapplePointVariations GrappleType) {};

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(GetIsSwinging())
		{
			FVector PlayerSwingLocation = PlayerOwner.ActorCenterLocation;
			PlayerSwingVelo = PlayerSwingLocation - CachedPlayerSwingLocation;

			CachedPlayerSwingLocation = PlayerSwingLocation;		
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Swing Arch Alpha"))
	float GetSwingArchAlpha() const
	{
		if(!GetIsSwinging())
			return 0.0;
	
		auto NormalizedSwingAngle = SwingComp.SwingAngle / 90.0;
		FVector ToSwing = (CurrentSwingPoint.WorldLocation - PlayerOwner.ActorCenterLocation).GetSafeNormal();
		const float SwingDirectionDot = PlayerSwingVelo.GetSafeNormal().DotProduct(ToSwing);

		const float SwingAlpha = NormalizedSwingAngle * (Math::Sign(SwingDirectionDot * -1));
		return NormalizedSwingAngle;
	}

	UFUNCTION(BlueprintPure, Meta = (HideSelfPin, CompactNodeTitle = "Swing Speed"))
	float GetSwingSpeed() const
	{
		if(!GetIsSwinging())
			return 0.0;

		auto SwingSpeed = Math::Min(1.0, PlayerSwingVelo.Size() / MAX_SWING_VELO_SPEED);
		return SwingSpeed;
	}
}