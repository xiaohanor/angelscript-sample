
class UIslandOverseerFloodAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerFloodAttackComponent FloodAttackComp;
	UIslandOverseerVisorComponent VisorComp;
	AIslandOverseerFlood Flood;

	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;

	bool bStartedEffects;
	FVector FloodStartLocation;
	FVector OwnerStartLocation;
	bool bCompletedFlood;
	bool bHoisting;
	float CompletedTime;
	TArray<AIslandOverseerFloodRespawnPoint> RespawnPoints;
	TPerPlayer<float> RespawnTimers;
	FHazeAcceleratedFloat SpeedAcc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		FloodAttackComp = UIslandOverseerFloodAttackComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);

		TListedActors<AIslandOverseerFloodRespawnPoint> Points;
		RespawnPoints = Points.GetArray();

		TListedActors<AIslandOverseerFlood> Floods;
		if(Floods.Num() > 0)
		{
			Flood = Floods[0];
			FloodStartLocation = Flood.ActorLocation;
		}
		OwnerStartLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bCompletedFlood)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(bCompletedFlood)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Flood, EBasicBehaviourPriority::Medium, this);
		VisorComp.Close();
		Flood.bEnabled = true;
		Flood.SetActorTickEnabled(true);
		UIslandOverseerEventHandler::Trigger_OnFloodAttackPrepare(Owner);
		FloodAttackComp.HoistComp.Hoist();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(6);

		FloodAttackComp.StopEffects();
		FloodAttackComp.StopFlood();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CompletedTime > 0)
		{
			if(Time::GetGameTimeSince(CompletedTime) > 1)
				bCompletedFlood = true;
			return;
		}

		if(!Flood.bDetachedLeftElevator && Flood.StartingElevatorLeft.WorldLocation.Z > Flood.LeftElevatorStop.ActorLocation.Z)
			Flood.DetachLeftElevator();

		if(!Flood.bDetachedRightElevator && Flood.StartingElevatorRight.WorldLocation.Z > Flood.RightElevatorStop.ActorLocation.Z)
			Flood.DetachRightElevator();

		if(ActiveDuration < 2.1)
			return;

		if(!bStartedEffects)
		{
			bStartedEffects = true;
			FloodAttackComp.StartEffects();
			UIslandOverseerFloodEventHandler::Trigger_OnElevatorStart(Flood);
		}

		FloodAttackComp.SetSplashOffset(FVector(0, 0, -Flood.ActorLocation.Distance(FloodAttackComp.WorldLocation)));

		if(ActiveDuration < 4)
			return;

		if(!FloodAttackComp.bFloodRunning)
			FloodAttackComp.StartFlood();

		AHazePlayerCharacter LowestTarget = Game::Mio;
		if(OtherIsAlive(LowestTarget))
			LowestTarget = LowestTarget.OtherPlayer;
		else if(OtherIsLower(LowestTarget))
			LowestTarget = LowestTarget.OtherPlayer;

		float Speed =  Settings.FloodBaseSpeed * Math::Clamp(Flood.GetVerticalDistanceTo(LowestTarget) / Settings.FloodCatchUpDistance, 0.5, 2);
		SpeedAcc.AccelerateTo(Speed, 1, DeltaTime);

		FVector Delta = FVector::UpVector * DeltaTime * SpeedAcc.Value;
		Flood.ActorLocation += Delta;

		if(!bHoisting && Flood.ActorLocation.Z >= OwnerStartLocation.Z + 50)
		{
			bHoisting = true;
			FloodAttackComp.HoistComp.HoistUp();
		}

		if(!FloodAttackComp.bPauseOwnerMovement)
		{
			if(Owner.ActorLocation.Z < Flood.ActorLocation.Z - 150)
				Delta *= 2;

			if(Owner.ActorLocation.Z < Flood.ActorLocation.Z - 100)
				Owner.ActorLocation += Delta;
		}

		// Stop flood
		if(Flood.ActorLocation.Z >= Flood.FloodStop.ActorLocation.Z)
		{
			CompletedTime = Time::GameTimeSeconds;
			AnimComp.RequestSubFeature(SubTagIslandOverseerFlood::End, this);
		}
	}

	private bool OtherIsAlive(AHazePlayerCharacter LowestTarget)
	{
		if(!LowestTarget.IsPlayerDead())
			return false;
		if(LowestTarget.OtherPlayer.IsPlayerDead())
			return false;
		return true;
	}

	private bool OtherIsLower(AHazePlayerCharacter LowestTarget)
	{
		if(LowestTarget.IsPlayerDead())
			return false;
		if(LowestTarget.OtherPlayer.IsPlayerDead())
			return false;
		if(LowestTarget.ActorUpVector.DotProduct(LowestTarget.ActorLocation - Flood.ActorLocation) < 0)
			return false;
		if(LowestTarget.OtherPlayer.ActorUpVector.DotProduct(LowestTarget.OtherPlayer.ActorLocation - Flood.ActorLocation) < 0)
			return false;
		if(Flood.GetVerticalDistanceTo(LowestTarget) < Flood.GetVerticalDistanceTo(LowestTarget.OtherPlayer))
			return false;
		return true;
	}
}