class ASanctuaryWeeperLightBird : AHazeCharacter
{
	access WeeperLightBirdInternal = private, USanctuaryWeeperLightBirdIlluminateCapability;

	default CapsuleComponent.CapsuleRadius = 50.0;
	default CapsuleComponent.CapsuleHalfHeight = 50.0;
	default CapsuleComponent.CollisionProfileName = n"PlayerCharacterAlternate";

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UPointLightComponent PointLightComponent;
	default PointLightComponent.SetCastShadows(false);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperLightBirdTransformCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperLightBirdMovementInputCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperLightBirdMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperLightBirdIlluminateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperLightBirdDashCapability");


	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float MinInputSize = 0.4;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float FacingInterpSpeed = 12.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float Acceleration = 2400.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float Deceleration = 3400.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float MovementSpeed = 650.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float DashMovementSpeed = 1400.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float DashDuration = 0.15;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Movement")
	float IlluminateMovementSpeed = 420.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird|Illuminate")
	float IlluminationRadius = 600.0;

	access: WeeperLightBirdInternal
	bool bIsIlluminating;
	
	AHazePlayerCharacter Player;
	bool bIsDashOnCooldown;
	bool bIsDashing;
	float DashCooldownDuration = 0.1;
	float TimeToEnableDash;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Player);

		CapsuleComponent.OverrideCapsuleRadius(50, this);
		CapsuleComponent.OverrideCapsuleHalfHeight(50, this);
	}

	UFUNCTION(BlueprintPure)
	bool IsIlluminating() const
	{
		return bIsIlluminating;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsDashOnCooldown)
			return; 

		if(bIsDashing)
			return;

		if(TimeToEnableDash <= Time::GameTimeSeconds)
		{
			bIsDashOnCooldown = false;
		}
	}

}