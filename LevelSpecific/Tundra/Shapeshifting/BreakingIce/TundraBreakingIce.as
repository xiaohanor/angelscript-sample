
event void FBreakIceEvent();

UCLASS(Abstract)
class ATundraBreakingIce : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = true;
	default Collision.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CrackEffect;
	default CrackEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent BreakEffect;
	default BreakEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"BlockAll";

	default PrimaryActorTick.bStartWithTickEnabled = false;

	FBreakIceEvent BreakIceEvent;
	TArray<AHazePlayerCharacter> OverlappedPlayers;
	bool bIsBroken = false;
	bool bIsTriggered = false;
	FVector MeshStartLocation;
	float TimeTriggered = 0;

	UPROPERTY(EditInstanceOnly)
	float DelayBeforeBreakingWhenHumanForm = 0.5;
	UPROPERTY(EditInstanceOnly)
	float ShakeMagnitude = 5.0;
	UPROPERTY(EditInstanceOnly)
	float SinkDistance = 50;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnterVolume");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"PlayerLeaveVolume");
		MeshStartLocation = Mesh.GetWorldLocation();
	}

	UFUNCTION()
	void PlayerEnterVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			OverlappedPlayers.Add(Player);
			ActorTickEnabled = true;
		}
	}

	UFUNCTION()
	void PlayerLeaveVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			OverlappedPlayers.Remove(Player);

			if(OverlappedPlayers.Num() <= 0)
			{
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(AHazePlayerCharacter Player : OverlappedPlayers)
		{
			UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
			if(MoveComp != nullptr)
			{
				if(MoveComp.IsOnAnyGround())
				{
					UTundraPlayerShapeshiftingComponent ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
					if(ShapeShiftComponent != nullptr)
					{
						Print("Player: " + Player, 0);
						// if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Small)
						// {



						switch(ShapeShiftComponent.CurrentShapeType)
						{
							case ETundraShapeshiftShape::None:
								return;
							case ETundraShapeshiftShape::Small:
								return;
							case ETundraShapeshiftShape::Player:
								TriggerIceBreaking(DelayBeforeBreakingWhenHumanForm); return;
							case ETundraShapeshiftShape::Big:
								TriggerIceBreaking(0.1); return;
						}
					}
				}
			}
		}

		if(bIsTriggered)
		{
			FVector MeshLocationOffset;
			float TimeTriggeredSqrd = TimeTriggered*TimeTriggered;
			MeshLocationOffset.Z = TimeTriggeredSqrd * -SinkDistance;
			MeshLocationOffset.X = Math::RandRange(-TimeTriggeredSqrd * ShakeMagnitude, TimeTriggeredSqrd * ShakeMagnitude);
			MeshLocationOffset.Y = Math::RandRange(-TimeTriggeredSqrd * ShakeMagnitude, TimeTriggeredSqrd * ShakeMagnitude);
			Mesh.SetWorldLocation(MeshStartLocation+MeshLocationOffset);

			TimeTriggered += DeltaSeconds;
		}
	}

	void TriggerIceBreaking(float DelayBeforeBreaking)
	{
		if(!bIsTriggered)
		{
			bIsTriggered = true;
			CrackEffect.Activate(true);
			Timer::SetTimer(this, n"BreakIce", DelayBeforeBreaking);
		}
	}

	UFUNCTION()
	void BreakIce()
	{
		if(!bIsBroken)
		{
			bIsBroken = true;
			BreakEffect.Activate(true);
			Collision.CollisionProfileName = n"NoCollision";
			Mesh.CollisionProfileName = n"NoCollision";
			SetActorHiddenInGame(true);
			BreakIceEvent.Broadcast();
			ActorTickEnabled = false;
		}		
	}
}