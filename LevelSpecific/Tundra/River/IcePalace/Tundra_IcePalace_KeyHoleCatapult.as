UCLASS(Abstract)
class ATundra_IcePalace_KeyHoleCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Stand;

	UPROPERTY(DefaultComponent, Attach=Root)
	UFauxPhysicsAxisRotateComponent FauxAxisRotator;
	default FauxAxisRotator.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach=FauxAxisRotator)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach=Collision)
	UFauxPhysicsWeightComponent FauxWeight;

	UPROPERTY(DefaultComponent, Attach=Collision)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent LaunchCollision;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComponent;
	default GroundSlamResponseComponent.bSetControlSideInBeginPlay = false;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToAttach;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactComponent;

	/* Which player should "control" this catapult over network */
	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerControlSide = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bNetworked = true;

	/* This force will be applied downwards at the location of the player when standing on catapult */
	UPROPERTY(EditAnywhere)
	float SmallForce = 50.0;

	/* This force will be applied downwards at the location of the player when standing on catapult */
	UPROPERTY(EditAnywhere)
	float PlayerForce = 200.0;

	/* This force will be applied downwards at the location of the player when standing on catapult */
	UPROPERTY(EditAnywhere)
	float BigForce = 200.0;

	UPROPERTY(EditAnywhere)
	float SmallLandImpulse = 25.0;

	/* This impulse will be applied downards at the location of the player when they land */
	UPROPERTY(EditAnywhere)
	float PlayerLandImpulse = 50.0;

	/* This impulse will be applied downards at the location of the big shape when they land */
	UPROPERTY(EditAnywhere)
	float BigLandImpulse = 100.0;

	UPROPERTY(EditAnywhere)
	float GroundedGroundSlamImpulse = 600;

	UPROPERTY(EditAnywhere)
	float AirborneGroundSlamImpulse = 600;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	bool bApplyForces = true;
	bool bApplyImpulses = true;

	UPROPERTY(EditInstanceOnly)
	AHazeActor LaunchPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bNetworked)
		{
			if(PlayerControlSide == EHazePlayer::Mio)
				SetActorControlSide(Game::Mio);
			else if(PlayerControlSide == EHazePlayer::Zoe)
				SetActorControlSide(Game::Zoe);
		}

		if(HasControl() || !bNetworked)
		{
			MovementImpactComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
			MovementImpactComponent.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnGroundImpactEnd");
			GroundSlamResponseComponent.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		}
		else
		{
			SetActorTickEnabled(false);
		}

		for(auto ActorToAttach : ActorsToAttach)
		{
			ActorToAttach.AttachToComponent(FauxAxisRotator, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		Players.AddUnique(Player);

		if(!bApplyImpulses)
			return;

		if(Player.ActorLocation.Z < FauxAxisRotator.WorldLocation.Z)
			return;

		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		if(ShapeshiftComp == nullptr || ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
			FauxAxisRotator.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * PlayerLandImpulse);
		else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			FauxAxisRotator.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * BigLandImpulse);
		else
			FauxAxisRotator.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * SmallLandImpulse);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGroundImpactEnd(AHazePlayerCharacter Player)
	{
		Players.Remove(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		if(!bApplyImpulses)
			return;

		if(GroundSlamType == ETundraPlayerSnowMonkeyGroundSlamType::Grounded)
			FauxAxisRotator.ApplyImpulse(Game::Mio.ActorLocation, -FVector::UpVector * GroundedGroundSlamImpulse);
		else
			FauxAxisRotator.ApplyImpulse(Game::Mio.ActorLocation, -FVector::UpVector * AirborneGroundSlamImpulse);

		PrintToScreen("FauxAxisRotator.PendingImpulses: " + FauxAxisRotator.PendingImpulses, 2);

		if(FauxAxisRotator.PendingImpulses <= -0.9)
		{
			if(LaunchCollision.IsOverlappingActor(Game::GetZoe()))
			{
				FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(Game::GetZoe().ActorLocation, LaunchPoint.ActorLocation, 2385, 1500);

				FPlayerLaunchToParameters Params;
				Params.Type = EPlayerLaunchToType::LaunchWithImpulse;
				Params.LaunchImpulse = Impulse;
				Game::GetZoe().LaunchPlayerTo(this, Params);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bApplyForces)
			return;

		for(int i = 0; i < Players.Num(); i++)
		{
			auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Players[i]);

			if(ShapeshiftComp == nullptr || ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
				FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * PlayerForce);
			else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
				FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * BigForce);
			else
				FauxAxisRotator.ApplyForce(Players[i].ActorLocation, -FVector::UpVector * SmallForce);
		}
	}
}