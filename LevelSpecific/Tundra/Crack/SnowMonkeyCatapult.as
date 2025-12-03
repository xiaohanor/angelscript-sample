event void FTundraSnowMonkeyCatapultMaxPointEvent(float RadiansPerSecond);
event void FTundraSnowMonkeyCatapultImpulseEvent(float CurrentRotatorVelocity);

UCLASS(Abstract)
class ASnowMonkeyCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

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
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComponent;
	default GroundSlamResponseComponent.bSetControlSideInBeginPlay = false;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToAttach;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

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
	TMap<AHazePlayerCharacter, float> TimeOfLand;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	bool bApplyForces = true;
	bool bApplyImpulses = true;

	float LastSlamTime = 0;
	bool bJustSlammed = false;

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

		if(TimeOfLand.Contains(Player) && Time::GetGameTimeSince(TimeOfLand[Player]) < 0.2)
			return;

		auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		float LandImpulse = BigLandImpulse;

		if(ShapeshiftComp == nullptr || ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
			LandImpulse = PlayerLandImpulse;
		else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Small)
			LandImpulse = SmallLandImpulse;

		if(Players.Contains(Game::Zoe))
		{
			FVector PlayerRelativeLocation = FauxAxisRotator.GetWorldTransform().InverseTransformPosition(Game::Zoe.ActorLocation);
			if(PlayerRelativeLocation.X > 0)
			{	
				if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
					LandImpulse *= 0.9;
				else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
					LandImpulse *= 0.3;
			}
		}

		FauxAxisRotator.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * LandImpulse);
		TimeOfLand.FindOrAdd(Player) = Time::GetGameTimeSeconds();
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

		float SlamImpulse = GroundedGroundSlamImpulse;
		
		if(GroundSlamType == ETundraPlayerSnowMonkeyGroundSlamType::Airborne)
			SlamImpulse = AirborneGroundSlamImpulse;


		if(Players.Contains(Game::Zoe))
		{
			FVector PlayerRelativeLocation = FauxAxisRotator.GetWorldTransform().InverseTransformPosition(Game::Zoe.ActorLocation);
			if(PlayerRelativeLocation.X > 0)
			{
				auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
				
				if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Player)
					SlamImpulse *= 0.9;
				else if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
					SlamImpulse *= 0.3;
			}
		}

		FauxAxisRotator.ApplyImpulse(Game::Mio.ActorLocation, -FVector::UpVector * SlamImpulse);

		if(HasControl())
			NetSetSlamTime();
	}

	UFUNCTION(NetFunction)
	void NetSetSlamTime()
	{
		LastSlamTime = Time::GameTimeSeconds;
		bJustSlammed = true;
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