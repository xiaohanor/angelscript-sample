UCLASS(Abstract)
class APigMazeEnemy : ABasicAIGroundMovementCharacter
{
	// default CapabilityComp.DefaultCapabilities.Add(n"PigMazeEnemyBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent)
	USphereComponent KillTrigger;
	default KillTrigger.SphereRadius = 200.0;

	UPROPERTY(EditInstanceOnly)
	AActor RespawnPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPigMazePowerupPlayerComponent PowerupComp = UPigMazePowerupPlayerComponent::Get(Player);
		if (PowerupComp == nullptr)
			return;

		if (PowerupComp.bPowerupActive)
		{
			BP_Kill();
			AddActorDisable(this);
			Timer::SetTimer(this, n"Respawn", 5.0);
		}
		else
		{
			Player.KillPlayer();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Kill() {}

	UFUNCTION()
	private void Respawn()
	{
		TeleportActor(RespawnPoint.ActorLocation, RespawnPoint.ActorRotation, this);
		RemoveActorDisable(this);
		BP_Respawn();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Respawn() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 30.0) * 10.0);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time::GameTimeSeconds * 20.0) * 10.0);
		FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);
		MeshOffsetComponent.SetRelativeRotation(Rotation);
	}
}