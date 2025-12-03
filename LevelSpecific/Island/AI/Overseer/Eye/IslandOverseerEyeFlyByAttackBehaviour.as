
class UIslandOverseerEyeFlyByAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Single");
	default CapabilityTags.Add(n"Attack");

	AAIIslandOverseerEye Eye;
	UIslandOverseerEyeSettings Settings;
	TArray<AHazePlayerCharacter> HitPlayers;
	bool bArrived;
	float TelegraphTime;
	// float Distance;
	bool bReverse;
	bool bStoppedTelegraph;
	FSplinePosition StartSplinePosition;
	UHazeSplineComponent CurrentSpline;
	UHazeSplineComponent NormalSpline;
	UHazeSplineComponent UpperSpline;
	FVector PreviousLocation;
	FRotator PreviousRotation; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		Settings = UIslandOverseerEyeSettings::GetSettings(Owner);
		NormalSpline = Eye.EyesComp.FlyBySplineActor.Spline;		
		UpperSpline = Eye.EyesComp.FlyByUpperSplineActor.Spline;
		bReverse = !Eye.bBlue;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!Eye.EyesManagerComp.CanAttack(Eye, EIslandOverseerEyeAttack::FlyBy))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		CurrentSpline = NormalSpline;
		if(Eye.bBlue && Eye.EyesManagerComp.CurrentPhase == EIslandOverseerAttachedEyePhase::ComboFlyBy)
			CurrentSpline = UpperSpline;

		Eye.EyesManagerComp.ClaimAttack(Eye);
		bArrived = false;
		TelegraphTime = 0;
		bStoppedTelegraph = false;

		float Distance = 0;
		if(bReverse)
			Distance = CurrentSpline.SplineLength;
		StartSplinePosition = FSplinePosition(CurrentSpline, Distance, true);

		PreviousLocation = Eye.ActorLocation;
		PreviousRotation = Eye.ActorRotation;
		Eye.Speed = Settings.FlyByMoveToSpeed;
		HitPlayers.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(Eye.EyesManagerComp != nullptr)
			Eye.EyesManagerComp.ReleaseAttack(Eye);
		bReverse = !bReverse;
		UIslandOverseerEyeEventHandler::Trigger_OnChargeTelegraphStop(Owner);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bArrived)
		{
			float Speed = Eye.Speed * Math::Clamp(Owner.ActorLocation.Distance(StartSplinePosition.WorldLocation) / 400, 0.1, 1);
			DestinationComp.MoveTowardsIgnorePathfinding(StartSplinePosition.WorldLocation, Speed);
			if(Owner.ActorLocation.PointsAreNear(StartSplinePosition.WorldLocation, 50))
			{
				bArrived = true;
				Eye.AccSpeed.SnapTo(0);
				Eye.Speed = Settings.FlyByAttackSpeed;
				UIslandOverseerEyeEventHandler::Trigger_OnChargeTelegraphStart(Owner);
				TelegraphTime = Time::GameTimeSeconds;
				DestinationComp.FollowSplinePosition = FSplinePosition(CurrentSpline, CurrentSpline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation), true);
			}
			return;
		}

		if(Time::GetGameTimeSince(TelegraphTime) < Settings.FlyByTelegraphDuration)
		{
			float AheadDistance = bReverse ? CurrentSpline.SplineLength - 50 : 50;
			FVector AheadLocation = CurrentSpline.GetWorldLocationAtSplineDistance(AheadDistance);
			FVector TelegraphDirection = (AheadLocation - DestinationComp.FollowSplinePosition.WorldLocation).ConstrainToPlane(Eye.Boss.ActorForwardVector).GetSafeNormal();
			DestinationComp.RotateInDirection(TelegraphDirection);
			UBasicAIMovementSettings::SetTurnDuration(Owner, Settings.FlyByTelegraphDuration, this);
			return;
		}

		if(!bStoppedTelegraph)
		{
			bStoppedTelegraph = true;
			UIslandOverseerEyeEventHandler::Trigger_OnFlybyTelegraphStop(Owner);
			UBasicAIMovementSettings::SetTurnDuration(Owner, 0, this);
		}
		
		Eye.AccSpeed.AccelerateTo(Eye.Speed, Settings.FlyByAttackAccelerationDuration, DeltaTime);
		DestinationComp.MoveAlongSpline(CurrentSpline, Eye.AccSpeed.Value, !bReverse);

		DamagePlayers();

		if(DestinationComp.IsAtSplineEnd(CurrentSpline, 1))
			DeactivateBehaviour();
	}

	private void DamagePlayers()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(HitPlayers.Contains(Player))
				continue;
			
			if(Player.ActorCenterLocation.PointPlaneProject(Eye.ActorLocation, Eye.Boss.ActorForwardVector).IsWithinDist(Owner.ActorLocation, 70))
			{
				HitPlayers.Add(Player);
				Player.DamagePlayerHealth(0.5, DamageEffect = Eye.DamageEffect, DeathEffect = Eye.DeathEffect);
				FKnockdown Knock;
				Knock.Duration = 1;
				Knock.Move = (Player.ActorLocation - Eye.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * 500;
				Player.ApplyKnockdown(Knock);
			}
		}
	}
}