event void FOnBighHogFart();

class ABigHog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Spine1")
	UCapsuleComponent BellyCollision;

	UPROPERTY(DefaultComponent)
	UBoxComponent FartDamageCollision;

	UPROPERTY(DefaultComponent, Category = "VFX")
	UNiagaraComponent FartVFX;


	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;
	default Camera.bCanUsePointOfInterest = false;


	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent)	
	UPigRainbowFartResponseComponent FartResponseComponent;


	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;


	UPROPERTY()
	FOnBighHogFart OnBigHogFart;

	access FartBoneScale = private, UBigHogFartCapability;
	access : FartBoneScale bool bFarting;
	access : FartBoneScale FVector FartBoneScale;

	AHazePlayerCharacter PlayerInstigator = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FartVFX.DeactivateImmediately();

		BellyCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginBellyOverlap");
		FartDamageCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnFartDamageOverlap");
	}

	void Fart()
	{
		OnBigHogFart.Broadcast();
		bFarting = true;
	}

	UFUNCTION()
	private void OnBeginBellyOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPlayerPigRainbowFartComponent RainbowFartComponent = UPlayerPigRainbowFartComponent::Get(Player);
		if (RainbowFartComponent == nullptr)
			return;

		if (RainbowFartComponent.IsFarting() && !bFarting)
		{
			PlayerInstigator = Player;

			Fart();

			FVector RedirectedVelocity = Math::GetReflectionVector(Player.ActorVelocity, (Player.ActorLocation - BellyCollision.WorldLocation).GetSafeNormal()).ConstrainToPlane(Player.MovementWorldUp);
			RedirectedVelocity += Player.MovementWorldUp * 1000;
			Player.SetActorVelocity(RedirectedVelocity);
		}
	}

	UFUNCTION()
	private void OnFartDamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		
	}

	UFUNCTION()
	bool IsFarting() const
	{
		
		return bFarting;
	}

	FVector GetFartBoneScale() const
	{
		return FartBoneScale;
	}
}