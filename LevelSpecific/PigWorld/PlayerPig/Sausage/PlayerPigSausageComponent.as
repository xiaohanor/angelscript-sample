enum EPigSausageMovementType
{
	FloppyForwardLateralRoll,
	Floppy,
	Roll
}

class UPlayerPigSausageComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APigSausage> PigSausageClass;
	APigSausage PigSausage;

	AHazePlayerCharacter PlayerOwner;

	UPigSausageGrillCapability GrillCapability;

	UPROPERTY()
	UHazeCameraSettingsDataAsset GrillCameraSettings;

	private bool bSausageActive;

	bool bIsOnGrill = false;
	FLinearColor SausageColor;
	float GrillValue = 0;

	bool bIsGrilled = false;
	bool bIsBurning = false;

	UPROPERTY()
	bool bIsKetchup = false;
	UPROPERTY()
	bool bIsMustard = false;

	private EPigSausageMovementType MovementType = EPigSausageMovementType::Floppy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION()
	void GrindPiggy()
	{
		PigSausage = SpawnActor(PigSausageClass);
		PigSausage.SplineMesh.SetMaterial(0, PigSausage.GetMaterialForPlayer(PlayerOwner));

		if(PlayerOwner.IsZoe())
		 	SausageColor = FLinearColor(FLinearColor(0.8,0.49,0.54,1));
		if(PlayerOwner.IsMio())
			SausageColor = FLinearColor(FLinearColor(0.63,0.56,0.55,1));

		PigSausage.SplineMesh.SetColorParameterValueOnMaterialIndex(0,n"Tint",SausageColor);


		PigSausage.AttachToComponent(PlayerOwner.MeshOffsetComponent);

		PlayerOwner.Mesh.SetHiddenInGame(true);
		PlayerOwner.BlockCapabilities(n"PlayerShadow", this);

		bSausageActive = true;

		PlayerOwner.BlockCapabilities(PlayerMovementTags::CoreMovement, this);

		auto VFXComp = UPlayerVFXSettingsComponent::Get(PlayerOwner);
		VFXComp.RelevantAttachRoot.Apply(PigSausage.SplineMesh, this);


		UPlayerMovementComponent::Get(PlayerOwner).SetupShapeComponent(PigSausage.CapsuleCollision);

		// PigSausage.KetchupMeshTEMP.SetVisibility(false);
		// PigSausage.MustardMeshTEMP.SetVisibility(false);
		
		// KetchupMesh = PigSausage.KetchupMeshTEMP;
		// MustardMesh = PigSausage.MustardMeshTEMP;

		}

	UFUNCTION(CrumbFunction, DevFunction)
	void Crumbed_AddKetchup()
	{
		AddKetchup();
	}

	UFUNCTION(CrumbFunction, DevFunction)
	void Crumbed_AddMustard()
	{
		AddMustard();
	}

	private void AddKetchup()
	{
		PigSausage.SplineMesh.SetMaterial(2,PigSausage.KetchupMaterial);
		bIsKetchup = true;

		FPigWorldSausageParams Params;
		Params.Player = PlayerOwner;

		if(bIsMustard && bIsGrilled)
			UPigSausageEventHandler::Trigger_SausageIsGrilledWithCondiments(PlayerOwner, Params);
	}

	private void AddMustard()
	{
		PigSausage.SplineMesh.SetMaterial(1,PigSausage.MustardMaterial);
		bIsMustard = true;

		FPigWorldSausageParams Params;
		Params.Player = PlayerOwner;

		if(bIsKetchup && bIsGrilled)
			UPigSausageEventHandler::Trigger_SausageIsGrilledWithCondiments(PlayerOwner, Params);
	}

	UFUNCTION(CrumbFunction)
	void Crumbed_RemoveCondiments()
	{
		RemoveCondiments();
	}

	private void RemoveCondiments()
	{
		PigSausage.SplineMesh.SetMaterial(2,PigSausage.MaskMaterial);
		PigSausage.SplineMesh.SetMaterial(1,PigSausage.MaskMaterial);
		bIsKetchup = false;
		bIsMustard = false;
	}

	UFUNCTION()
	void ResurrectPiggy()
	{
		PigSausage.DestroyActor();
		PigSausage = nullptr;

		PlayerOwner.Mesh.SetHiddenInGame(false);

		bSausageActive = false;

		PlayerOwner.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
	}

	float GetGirth() const
	{
		return PigSausage.Girth;
	}

	float GetHalfGirth() const
	{
		return GetGirth() * 0.5;
	}

	FVector GetMeshHeightOffset() const
	{
		return PlayerOwner.MovementWorldUp * GetHalfGirth();
	}

	bool IsSausageActive() const
	{
		return bSausageActive;
	}

	void SetMovementType(EPigSausageMovementType Movement)
	{
		MovementType = Movement;
	}

	EPigSausageMovementType GetCurrentMovement() const
	{
		return MovementType;
	}

	float GetBouncyMeshDamping() const
	{
		return bIsGrilled ? 0.6 : 0.2;
	}

	UFUNCTION()
	void StartGrill()
	{
		bIsOnGrill = true;
		Cast<AHazePlayerCharacter>(Owner).ApplyCameraSettings(GrillCameraSettings,2,this,EHazeCameraPriority::High);
	}

	UFUNCTION()
	void StopGrill()
	{
		bIsOnGrill = false;
		Cast<AHazePlayerCharacter>(Owner).ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION()
	void GrillHotDog(float DeltaTime)
	{
		if(PlayerOwner.HasControl())
		{
			GrillValue += DeltaTime/6;
			if(!bIsGrilled && GrillValue >= 1)
			{
				CrumbMakeHotDogReady();
			}
			if(!bIsBurning && GrillValue >= 2)
			{
				CrumbBurnHotDog();
			}
		}

		// else if (GrillValue < 1)
		// {
		// 	PigSausage.SplineMesh.SetMaterial(0, PigSausage.GetMaterialForPlayer(PlayerOwner));

		// 	FLinearColor NewColor;
		// 	FLinearColor ZoeGrillColor = FLinearColor(0.17,0.05,0.07,1);
		// 	FLinearColor MioGrillColor = FLinearColor(0.22,0.07,0.05,1);

		// 	GrillValue += DeltaTime/6;
		// 	float Alpha = Math::Clamp(GrillValue,0,1);

		// 	// if(PlayerOwner.IsZoe())
		// 	// 	NewColor = Math::Lerp(SausageColor, ZoeGrillColor, Alpha);
		// 	// if(PlayerOwner.IsMio())
		// 	// 	NewColor = Math::Lerp(SausageColor, MioGrillColor, Alpha);

		// 	// PigSausage.SplineMesh.SetColorParameterValueOnMaterialIndex(0,n"Tint",NewColor);
		// }

		// //Print(""+GrillValue);
	}	

	UFUNCTION()
	private void DeathTimer()
	{
		PlayerOwner.KillPlayer();
		GrillValue = 0;

		FPigWorldSausageParams Params;
		Params.Player = PlayerOwner;

		UPigSausageEventHandler::Trigger_StopFireEvent(PlayerOwner);
		UPigSausageEventHandler::Trigger_StopSmokeEvent(PlayerOwner);
		UPigSausageEventHandler::Trigger_ExplosionEvent(PlayerOwner,Params);
		bIsBurning = false;
		bIsGrilled = false;

		PigSausage.SplineMesh.SetMaterial(0, PigSausage.GetMaterialForPlayer(PlayerOwner));
	}

	UFUNCTION(CrumbFunction, DevFunction)
	private void CrumbMakeHotDogReady()
	{
		FPigWorldSausageParams Params;
		Params.Player = PlayerOwner;
		UPigSausageEventHandler::Trigger_HotDogReadyEvent(PlayerOwner,Params);
		bIsGrilled = true;
		if(PlayerOwner.IsZoe())
			PigSausage.SplineMesh.SetMaterial(0,PigSausage.ZoeGrillMaterial);
		else
			PigSausage.SplineMesh.SetMaterial(0,PigSausage.MioGrillMaterial);
	}

	UFUNCTION(CrumbFunction, DevFunction)
	private void CrumbBurnHotDog()
	{
		bIsBurning = true;
		FPigWorldSausageParams Params;
		Params.Player = PlayerOwner;
		UPigSausageEventHandler::Trigger_StartFireEvent(PlayerOwner,Params);
		PigSausage.SplineMesh.SetMaterial(0,PigSausage.BurnGrillMaterial);

		Timer::SetTimer(this,n"DeathTimer",2,false,0,0);
	}
}



UFUNCTION(Category = "PigWorld")
void GrindPlayerPigsIntoSausages()
{
	for (auto Player : Game::Players)
	{
		UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(Player);
		if (PigSausageComponent != nullptr)
			PigSausageComponent.GrindPiggy();
	}
}

UFUNCTION(Category = "PigWorld")
void SetPigSausageMovementTypeForPlayer(AHazePlayerCharacter Player, EPigSausageMovementType MovementType)
{
	UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(Player);
	if (PigSausageComponent != nullptr)
		PigSausageComponent.SetMovementType(MovementType);
}

UFUNCTION(Category = "PigWorld")
void SetPigSausageKetchupVisiblity(AHazePlayerCharacter Player)
{
	UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(Player);
	if (PigSausageComponent != nullptr)
	{
		if (Player.HasControl())
			PigSausageComponent.Crumbed_AddKetchup();
	}
}

UFUNCTION(Category = "PigWorld")
void SetPigSausageMustardVisiblity(AHazePlayerCharacter Player)
{
	UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(Player);
	if (PigSausageComponent != nullptr)
	{
		if (Player.HasControl())
			PigSausageComponent.Crumbed_AddMustard();
	}
}

UFUNCTION(Category = "PigWorld")
void StopPlayerPigSausages()
{
	for (auto Player : Game::Players)
	{
		UPlayerPigSausageComponent PigSausageComponent = UPlayerPigSausageComponent::Get(Player);
		if (PigSausageComponent != nullptr)
			PigSausageComponent.ResurrectPiggy();
	}
}