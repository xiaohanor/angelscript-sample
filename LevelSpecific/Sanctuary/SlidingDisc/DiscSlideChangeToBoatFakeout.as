UCLASS(Abstract)
class ADiscSlideChangeToBoatFakeout : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TSoftObjectPtr<ASanctuaryBoat> SanBoat;

	UPROPERTY(EditAnywhere)
	ASlidingDisc SlidingDisc;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditAnywhere)
	AActor RefActor;
	bool bHasRunTick = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlidingDisc.OnBecomeVisualBoatThanks.AddUFunction(this, n"ChangeIntoBoatActorVisual");
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bHasRunTick = true;
		if(!HasControl())
			return;

		if (SlidingDisc == nullptr) // can maybe happen when disc gets destroyed when players die in a pit etc
			return;

		if (!SanBoat.IsValid())
			return;

		if (RefActor == nullptr)
			return;

		if(SlidingDisc.GetDistanceTo(RefActor) < 300.0)
		{
			CrumbPerformCompleteSwitch(SlidingDisc.ActorLocation, SlidingDisc.Pivot.WorldRotation, SlidingDisc.ActorVelocity);
		}
		else if (SlidingDiscDevToggles::DrawBoat.IsEnabled())
		{
			PrintToScreen("Distance: " + SlidingDisc.GetDistanceTo(RefActor));
		}
	}

	private int SanityGuardTries = 0;

	UFUNCTION()
	private void ChangeIntoBoatActorVisual()
	{
		SanityGuardTries++;
		if (SanityGuardTries > 2) // something is wrong, this actor is disabled or such
			return;
		if (!bHasRunTick)
		{
			// delay one frame because we shouldn't attach teleport players the first frame onto faux physics
			ActionQueueComp.Idle(0.01);
			ActionQueueComp.Event(this, n"ChangeIntoBoatActorVisual");
			return;
		}
		if(HasControl())
		{
			if (Network::IsGameNetworked())
				Game::Mio.BlockCapabilities(n"SyncLocationMeshOffset", this); // mio doesn't own network boat, and can look jank
			CrumbChangeIntoBoatActorVisual(SlidingDisc.ActorLocation, SlidingDisc.Pivot.WorldRotation); // SlidingDisc.Pivot.WorldRotation
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChangeIntoBoatActorVisual(FVector Location, FRotator Rotation)
	{
		SanBoat.Get().ClearAllDisables();
		SanBoat.Get().AddActorCollisionBlock(this);
		// SlidingDisc.AddActorCollisionBlock(this);
		
		SlidingDisc.IgnoreCollisionBoat = SanBoat.Get();

		SanBoat.Get().TeleportActor(Location, FRotator::MakeFromXZ(Rotation.ForwardVector, FVector::UpVector), this);
		SanBoat.Get().SuperHackySnapToDisc = SlidingDisc;

		for (auto Player : Game::Players)
		{
			UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComp.FindGround(100);
			MoveComp.FollowComponentMovement(SanBoat.Get().AttachmentRoot, this, EMovementFollowComponentType::Teleport, EInstigatePriority::High);
			USlidingDiscPlayerComponent DiscComp = USlidingDiscPlayerComponent::Get(Player);
			DiscComp.bInWaterSwitchSegment = true;
			// Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		}

		SlidingDisc.AddActorVisualsBlock(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPerformCompleteSwitch(FVector Location, FRotator Rotation, FVector Velocity)
	{
		for (auto Player : Game::Players)
		{
			USlidingDiscPlayerComponent DiscComp = USlidingDiscPlayerComponent::Get(Player);
			DiscComp.bInWaterSwitchSegment = false;
			UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComp.UnFollowComponentMovement(this);
			// Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
			if (HasControl() && Network::IsGameNetworked() && Player.IsMio())
				Player.UnblockCapabilities(n"SyncLocationMeshOffset", this);
		}

		SanBoat.Get().RemoveActorCollisionBlock(this);
		// SlidingDisc.RemoveActorCollisionBlock(this);

		SanBoat.Get().SuperHackySnapToDisc = nullptr;
		SlidingDisc.AddActorDisable(this);
		SanBoat.Get().MoveComp.AddPendingImpulse(Velocity, this);

		DestroyActor();

		for (auto Player : Game::Players)
		{
			UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComp.FindGround(100);
		}
	}
};