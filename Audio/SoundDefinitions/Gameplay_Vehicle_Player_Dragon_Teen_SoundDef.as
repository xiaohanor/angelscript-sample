enum EDragonFootstepMovementType
{
	Walk,
	Jog,
	Run,
	Release
}

struct FDragonFootstepEventData
{
	UPROPERTY()
	UHazeAudioEvent WalkPlantEvent;

	UPROPERTY()
	UHazeAudioEvent RunPlantEvent;

	UPROPERTY()
	UHazeAudioActorMixer WalkAmix;
	
	UPROPERTY()
	UHazeAudioActorMixer RunAmix;
}

struct FDragonLandEventData
{
	UPROPERTY()
	UHazeAudioEvent LandEvent;

	UPROPERTY()
	UHazeAudioActorMixer LandAmix;
}

struct FDragonFootstepEventDatas
{
	UPROPERTY()
	TMap<EHazeAudioPhysicalMaterialHardnessType, FDragonFootstepEventData> FootstepEventDatas;
}

UCLASS(Abstract)
class UGameplay_Vehicle_Player_Dragon_Teen_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void AcidTeenGlideStart(){}

	UFUNCTION(BlueprintEvent)
	void AcidTeenGlideStop(){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_Setup(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepRelease(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_FrontLeft(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_FrontRight(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_BackLeft(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_BackRight(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepLand(FDragonFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void AcidTeenBoostRingStart(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnFootstepPlant_Climb() {}

	UFUNCTION(BlueprintEvent)
	void OnFootstepRelease_Climb() {}

	UFUNCTION(BlueprintEvent)
	void OnFootstepEnterLand_Climb() {}

	UFUNCTION(BlueprintEvent)
	void OnFootstepEnter_Climb() {}

	UFUNCTION(BlueprintEvent)
	void OnFootstepEnter_Dash() {}

	UHazeMovementComponent PlayerMoveComp;
	UPlayerTeenDragonComponent DragonComp;

	UPROPERTY(BlueprintReadOnly)
	UDragonMovementAudioComponent DragonMoveComp;
	
	const FHazeAudioID PanningRTPCId = FHazeAudioID("Rtpc_SpeakerPanning_LR");
	const FName DragonFootGroupName = n"Dragon_Foot";
	const FName DragonClimbGroupName = n"Dragon_Climb";

	FVector LastDragonLocation;
	FVector LastSpineSocketLocation;

	FVector LastDragonForward;
	float AngularDelta = 0;
	FVector SpineSocketRelativeVelo;

	UPROPERTY(BlueprintReadWrite, NotVisible)
	float NormalizedSpeed = 0;

	UPROPERTY(BlueprintReadWrite, NotVisible, Category = BodyMovement)
	float NormalizedBodyMovement = 0;
	
	UPROPERTY(BlueprintReadWrite, NotVisible)
	float BodyMovementFootstepMultiplier = 1;

	UPROPERTY(BlueprintReadWrite, NotVisible, Category = "Foot")
	EHazeAudioPhysicalMaterialHardnessType HardnessType = EHazeAudioPhysicalMaterialHardnessType::Soft;

	UPROPERTY(BlueprintReadWrite, NotVisible, Category = "Foot")
	EDragonFootType FootType = EDragonFootType::BackLeft;

	UPROPERTY(BlueprintReadWrite, NotVisible, Category = "Foot")
	float CurrentFootstepPitch = 0;

	UPROPERTY(BlueprintReadWrite, NotVisible, Category = "Foot")
	float CurrentFootstepMakeUpGain = 0;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	AHazePlayerCharacter DragonRiderPlayer = nullptr;
		
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Foot")
	TMap<EDragonFootType, FDragonFootstepEventDatas> FootstepDatas;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Foot")
	TMap<EHazeAudioPhysicalMaterialHardnessType, UHazeAudioEvent> ReleaseEvents;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Foot")
	TMap<EHazeAudioPhysicalMaterialHardnessType, FDragonLandEventData> LandEventDatas;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = BodyMovement)
	UHazeAudioEvent BodyMovementEvent;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = BodyMovement)
	float BodyMovementSlewAttack = 0.3;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = BodyMovement)
	float BodyMovementSlewRelease = 0.3;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = BodyMovement)
	float BodyMovementLowIntCurvePower = 0.25;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = BodyMovement)
	float BodyMovementHighIntCurvePower = 1.75;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = Jumping)
	float MaxJumpHeight = 150;

	private bool bWasGrounded = true;
	private bool bShouldQueryJumpApex = false;

	private FVector LastAirborneLocation;
	private FVector JumpApexLocation;
	private float FallingSpeed = 0;

	UFUNCTION(BlueprintEvent)
	void OnEnterWater() {};

	UFUNCTION(BlueprintEvent)
	void OnExitWater() {};

	UFUNCTION(BlueprintEvent)
	void OnEnterCoins() {};

	UFUNCTION(BlueprintEvent)
	void OnExitCoins() {};

	const FName WATER_PHYSMAT_NAME = n"Env_Water_Puddle";

	int OverlappingWaterPlanesCount = 0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DragonComp = Cast<ATeenDragon>(HazeOwner).GetDragonComponent();
		DragonRiderPlayer = DragonComp.IsAcidDragon() ? Game::GetMio() : Game::GetZoe();

		PlayerMoveComp = UHazeMovementComponent::Get(DragonComp.GetOwner());
		DragonMoveComp = UDragonMovementAudioComponent::Get(HazeOwner);

		const float PlayerPanningValue =  DragonRiderPlayer.IsMio() ? -1.0 : 1.0;
		DefaultEmitter.SetRTPC(PanningRTPCId, PlayerPanningValue, 0);

		auto WaterColliderComp = UPrimitiveComponent::Get(HazeOwner, n"WaterCollision");
		if(WaterColliderComp != nullptr)
		{
			WaterColliderComp.OnComponentBeginOverlap.AddUFunction(this, n"OnWaterOverlapBegin");
			WaterColliderComp.OnComponentEndOverlap.AddUFunction(this, n"OnWaterOverlapEnd");
		}		
		
		UDragonFootstepTraceComponent DragonTraceComp = UDragonFootstepTraceComponent::Get(DragonRiderPlayer);
		DragonTraceComp.OnEnterCoins.AddUFunction(this, n"OnEnterCoins");
		DragonTraceComp.OnExitCoins.AddUFunction(this, n"OnExitCoins");
		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, DragonRiderPlayer);
	}

	UFUNCTION()
	void OnWaterOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent Othercomp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(Othercomp.NumMaterials == 0)
			return;

		UMaterialInterface PrimaryMaterial = Othercomp.GetMaterial(0);
		if(PrimaryMaterial == nullptr)
			return;

		UPhysicalMaterial PhysMat = PrimaryMaterial.GetPhysicalMaterial();
		if(PhysMat == nullptr)
			return;

		if(PhysMat.Name != WATER_PHYSMAT_NAME)
			return;

		if (OverlappingWaterPlanesCount == 0)
			OnEnterWater();

		++OverlappingWaterPlanesCount;
	}

	UFUNCTION()
	void OnWaterOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent Othercomp, int OtherBodyIndex)
	{
		if(Othercomp.NumMaterials == 0)
			return;

		UMaterialInterface PrimaryMaterial = Othercomp.GetMaterial(0);
		if(PrimaryMaterial == nullptr)
			return;

		UPhysicalMaterial PhysMat = PrimaryMaterial.GetPhysicalMaterial();
		if(PhysMat == nullptr)
			return;

		if(PhysMat.Name != WATER_PHYSMAT_NAME)
			return;

		--OverlappingWaterPlanesCount;

		if(OverlappingWaterPlanesCount == 0)
			OnExitWater();
	}
	
	UFUNCTION(BlueprintPure)
	FDragonFootstepEventData GetFootEventData(const EDragonFootstepMovementType Type)
	{
		FDragonFootstepEventDatas EventDatas;
		if(FootstepDatas.Find(FootType, EventDatas))
		{			
			FDragonFootstepEventData EventData;
			EventDatas.FootstepEventDatas.Find(HardnessType, EventData);
			return EventData;				
			
		}

		return FDragonFootstepEventData();
	}

	UFUNCTION(BlueprintPure)
	float GetDistanceToPlayerCamera()
	{
		return DragonComp.DragonMesh.GetWorldLocation().Distance(DragonRiderPlayer.GetViewLocation());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector CurrForward = DragonComp.DragonMesh.ForwardVector;
		AngularDelta = CurrForward.DotProduct(LastDragonForward);
		LastDragonForward = CurrForward;

		FVector SpineSocketLocation = DragonComp.DragonMesh.GetSocketLocation(MovementAudio::Dragons::SpineSocketName);
		FVector DragonLocation = DragonRiderPlayer.GetActorCenterLocation();

		FVector DragonVelo = DragonLocation - LastDragonLocation;
		SpineSocketRelativeVelo = (SpineSocketLocation - LastSpineSocketLocation) - DragonVelo;

		const bool bIsGrounded = PlayerMoveComp.IsOnAnyGround();
		QueryFalling(bIsGrounded);
		bWasGrounded = bIsGrounded;
			
		if(!bIsGrounded)
			LastAirborneLocation = DragonComp.DragonMesh.GetWorldLocation();	

		LastSpineSocketLocation = SpineSocketLocation;
		LastDragonLocation = DragonLocation;

		BodyMovementFootstepMultiplier = Math::FInterpConstantTo(BodyMovementFootstepMultiplier, 0, DeltaSeconds, 5.0);
	}

	UFUNCTION(BlueprintPure)
	float GetDragonAngularVelocity()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.97, 1), FVector2D(1, 0), AngularDelta);
	}

	UFUNCTION(BlueprintPure)
	float GetDragonTilt()
	{		
		FVector Forward = DragonComp.DragonMesh.GetSocketRotation(MovementAudio::Dragons::SpineSocketName).ForwardVector;
		const float TiltDegrees = Forward.DotProduct(PlayerMoveComp.WorldUp);
		return TiltDegrees;		
	}

	UFUNCTION(BlueprintPure)
	float GetBodyMovementRelativeSpeed()
	{
		return SpineSocketRelativeVelo.Size();
	}

	UFUNCTION(BlueprintPure)
	float IsInAirValue()
	{
		return PlayerMoveComp.IsInAir() ? 1.0 : 0.0;
	}	

	UFUNCTION(BlueprintPure)
	bool IsInWater()
	{
		return OverlappingWaterPlanesCount > 0;
	}

	UFUNCTION(BlueprintPure)
	float GetBodyMovementFootstepMultiplier()
	{
		return BodyMovementFootstepMultiplier;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldTickClimbing()
	{
		return DragonMoveComp.IsGroupActive(DragonClimbGroupName);
	}

	UFUNCTION(BlueprintPure)
	float GetFallingSpeed()
	{
		return FallingSpeed;
	}
	
	private void QueryFalling(const bool bInIsGrounded)
	{
		if(bWasGrounded && !bInIsGrounded)
		{
			bShouldQueryJumpApex = true;
		}
		else if(!bWasGrounded && bInIsGrounded)
		{			
			const float VerticalDelta = JumpApexLocation.Z - DragonComp.DragonMesh.GetWorldLocation().Z;
			FallingSpeed = Math::Clamp(VerticalDelta / MaxJumpHeight, 0.0, 1.0);					
		}

		if(bShouldQueryJumpApex)
		{
			const bool bHasStartedFalling = DragonMoveComp.IsGroupTagActive(DragonFootGroupName, n"Falling");
			if(bHasStartedFalling)
			{
				bShouldQueryJumpApex = false;
				JumpApexLocation = DragonComp.DragonMesh.GetWorldLocation();
			}
		}		
	}
}