/**
 * Handles throwing the player off if we get a wall impact while on the Tazer bot d-, uhm, "stick"
 */
class UTazerBotPerchWallImpactCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;

	UPlayerPerchComponent PerchComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchComp = UPlayerPerchComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!IsPerchingOnTazerBotStick())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsPerchingOnTazerBotStick())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		check(HasControl());

		auto TazerBot = Cast<ATazerBot>(PerchComp.Data.ActiveSpline.AttachParentActor);

		if(!IsTazerBotMoving(TazerBot))
			return;

		if(MoveComp.AllWallImpacts.IsEmpty())
			return;

		// Follow found a wall impact
		const FHitResult& FirstWallImpact = MoveComp.AllWallImpacts[0];
		const FVector KnockdownDirection = FirstWallImpact.Normal.GetSafeNormal2D(MoveComp.WorldUp);
		CrumbKnockDown(TazerBot, KnockdownDirection);
	}

	UFUNCTION(CrumbFunction)
	void CrumbKnockDown(ATazerBot TazerBot, FVector KnockdownDirection)
	{
		PerchComp.StopPerching();

		FKnockdown Knockdown;
		Knockdown.Move = KnockdownDirection;
		Knockdown.Duration = TazerBot.KnockdownParams.Duration;
		Knockdown.StandUpDuration = TazerBot.KnockdownParams.StandUpDuration;
		Player.ApplyKnockdown(Knockdown);

		Player.AddKnockbackImpulse(KnockdownDirection, 400, 300);

		Player.PlayCameraShake(TazerBot.KnockdownCamShake, this);
		Player.PlayForceFeedback(TazerBot.KnockDownFF, false, true, this);

		FTazerBotOnPlayerKnockedDownByMovingIntoWallParams EventData;
		EventData.KnockedPlayer = Player;
		EventData.KnockdownDuration = Knockdown.Duration;
		EventData.StandUpDuration = Knockdown.StandUpDuration;
		UTazerBotEventHandler::Trigger_OnPlayerKnockedDownByMovingIntoWall(TazerBot, EventData);
	}

	bool IsPerchingOnTazerBotStick() const
	{
		if(!PerchComp.IsCurrentlyPerching())
			return false;

		if(PerchComp.Data.ActiveSpline == nullptr)
			return false;

		if(PerchComp.Data.ActiveSpline.AttachParentActor == nullptr)
			return false;

		if(!PerchComp.Data.ActiveSpline.AttachParentActor.IsA(ATazerBot))
			return false;

		return true;
	}

	bool IsTazerBotMoving(ATazerBot TazerBot) const
	{
		if(TazerBot == nullptr)
			return false;

		// PrintToScreen(f"{TazerBot.ActorVelocity.Size()=}");
		// PrintToScreen(f"{TazerBot.CrumbedAngularSpeed.Value=}");

		if(!TazerBot.ActorVelocity.VectorPlaneProject(FVector::UpVector).IsNearlyZero(TazerBot.PerchWallImpactMovementSpeedThreshold))
			return true;

		if(!Math::IsNearlyZero(TazerBot.CrumbedAngularSpeed.Value, TazerBot.PerchWallImpactAngularSpeedThreshold))
			return true;

		return false;
	}
};