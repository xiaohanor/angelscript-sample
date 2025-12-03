event void FPigStretchEvent();

class UPlayerPigStretchyLegsComponent : UActorComponent
{
	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset StretchedCamSettings;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> StretchedShake;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> FlipCameraShake;

	UPROPERTY(Category = "Dizzy")
	UForceFeedbackEffect ForceFeedback_Dizzy;

	UPROPERTY(Category = "Dizzy")
	TSubclassOf<AHazeActor> DizzyStarsClass;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect StretchForceFeedback;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect FlipForceFeedback;

	UPROPERTY()
	USkeletalMesh SpringyMesh;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeCharacterSkeletalMeshComponent SpringyMeshComponent;

	UPROPERTY()
	FPigStretchEvent OnPigStretched;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnterFailHeight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnterFailed;

	AHazePlayerCharacter PlayerOwner;

	access Stretch = private, UPigStretchyLegsCapability;
	access : Stretch bool bStretching = false;
	access : Stretch bool bStretched = false;

	access Flip = private, UPigStretchyLegsCapability, UPigStretchyLegsFlipCapability;
	access : Flip bool bShouldFlip = false;
	access : Flip bool bAirborneAfterStretching = false;

	access Dizzy = private, UPigStretchyLegsCapability, UPigDizzyCapability;
	access : Dizzy bool bDizzy = false;

	bool bWasGrounded = false;

	private	bool bSpringyMeshActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		UPlayerPigComponent PlayerPigComponent = UPlayerPigComponent::Get(Owner);
		if (PlayerPigComponent == nullptr)
			return;

		// Create springy mesh, attach to player and make invisible
		SpringyMeshComponent = UHazeCharacterSkeletalMeshComponent::GetOrCreate(PlayerOwner, n"SpringyMeshComponent");
		SpringyMeshComponent.SetSkeletalMeshAsset(SpringyMesh);
		SpringyMeshComponent.AttachToComponent(PlayerOwner.MeshOffsetComponent);
		SpringyMeshComponent.SetScalarParameterValueOnMaterials(n"DitherFade", 0.0);
		SpringyMeshComponent.SetShadowPriorityRuntime(EShadowPriority::Player);
		SpringyMeshComponent.SetCastShadow(true);

		// Set anim class and feature
		SpringyMeshComponent.SetAnimClass(PlayerOwner.Mesh.AnimInstance.GetClass());
		SpringyMeshComponent.AddLocomotionFeatureBundle(PlayerPigComponent.ZoeFeature, this, 200);

		// This will copy player mesh requested tag onto stretchy pig
		PlayerOwner.Mesh.LinkMeshComponentToLocomotionRequests(SpringyMeshComponent);
	}

	UFUNCTION()
	bool IsStretching() const
	{
		return bStretching;
	}

	UFUNCTION()
	bool IsStretched() const
	{
		return bStretched;
	}

	UFUNCTION()
	bool IsAirborneAfterStretching() const
	{
		return bAirborneAfterStretching;
	}

	void ApplySpringyMesh()
	{
		bSpringyMeshActive = true;
	}

	void ClearSpringyMesh()
	{
		bSpringyMeshActive = false;
	}

	bool IsSpringyMeshActive() const
	{
		return bSpringyMeshActive;
	}
}