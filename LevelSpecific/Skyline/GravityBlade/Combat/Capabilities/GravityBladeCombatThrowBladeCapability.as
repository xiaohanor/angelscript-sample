class UGravityBladeCombatThrowBladeCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerMovementComponent MoveComp;

	FVector StartLocation;
	float ThrowDuration;
	FHazeRuntimeSpline BladeSpline;
	bool bAttached = false;
	bool bPulling = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Player);
		BladeComp = UGravityBladeUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CombatComp.ThrowBladeData.IsValid())
			return false;

		if(!BladeComp.IsBladeEquipped())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.ThrowBladeData.IsValid())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bAttached = false;
		bPulling = false;
		StartLocation = BladeComp.Blade.ActorLocation;
		const float NewLength = RecalculateSpline();
		ThrowDuration = (NewLength / GravityBladeGrapple::ThrowSpeed);

		BladeComp.UnequipBlade();

		FGravityBladeThrowData ThrowData;
		ThrowData.Location = Player.Mesh.GetSocketLocation(n"RightAttach");
		ThrowData.Normal = BladeComp.Blade.ActorUpVector;
		ThrowData.ThrowDuration = ThrowDuration;
		UGravityBladeGrappleEventHandler::Trigger_StartThrow(BladeComp.Blade, ThrowData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bPulling)
			UGravityBladePlayerEventHandler::Trigger_EndPull(Player);
		
		BladeComp.EquipBlade(0.15);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bPulling && ActiveDuration >= CombatComp.ThrowBladeData.DelayBeforePulling)
		{
			UGravityBladePlayerEventHandler::Trigger_StartPull(Player);
			bPulling = true;
		}

		if(!bAttached && CombatComp.ThrowBladeData.IsValid())
		{
			// Recalculate the spline if the target has moved away
			const FVector TargetLocationDelta = (BladeSpline.Points.Last() - CombatComp.ThrowBladeData.Target.WorldLocation);
			if (!TargetLocationDelta.IsNearlyZero(SMALL_NUMBER))
				RecalculateSpline();

			float Alpha = Math::Saturate(ActiveDuration / ThrowDuration);
			Alpha = Math::EaseIn(0.0, 1.0, Alpha, 4.0);

			const FVector BladeLocation = BladeSpline.GetLocation(Alpha);
			const FVector BladeDirection = BladeSpline.GetDirection(Alpha);
			const FRotator BladeRotation = FRotator::MakeFromZX(BladeDirection, -Player.MovementWorldUp);

			BladeComp.Blade.SetActorLocationAndRotation(
				BladeLocation,
				BladeRotation
			);

			if(Math::IsNearlyEqual(Alpha, 1.0))
			{
				BladeComp.Blade.AttachToActor(CombatComp.ThrowBladeData.Target.Owner, NAME_None, EAttachmentRule::KeepWorld);
				bAttached = true;

				FGravityBladeThrowData ThrowData;
				ThrowData.Location = BladeComp.Blade.ActorLocation;
				ThrowData.Normal = BladeComp.Blade.ActorUpVector;
				UGravityBladeGrappleEventHandler::Trigger_EndThrow(BladeComp.Blade, ThrowData);
			}
		}
	}

	private float RecalculateSpline()
	{
		BladeSpline = FHazeRuntimeSpline();
		BladeSpline.AddPoint(StartLocation);
		BladeSpline.AddPoint(CombatComp.ThrowBladeData.Target.WorldLocation);
		BladeSpline.SetCustomExitTangentPoint(CombatComp.ThrowBladeData.Target.WorldLocation - MoveComp.WorldUp);
		BladeSpline.SetCustomCurvature(0.9);

		return BladeSpline.Length;
	}
}