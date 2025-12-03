event void FIslandVaultDoor_OnCenterPieceShot(float Progress);
event void FIslandVaultDoor_Event();


class AIslandStormdrainBankVaultDoor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent, Attach = "RootComponent")
	USceneComponent Hinge;

	UPROPERTY(DefaultComponent, Attach = "Hinge")
	USceneComponent MeshScene;

	UPROPERTY(DefaultComponent, Attach = "MeshScene")
	UStaticMeshComponent VaultDoorMesh;

	UPROPERTY(DefaultComponent, Attach = "MeshScene")
	UStaticMeshComponent VaultDoorMesh_SpinnCenter;

	UPROPERTY(DefaultComponent, Attach = "VaultDoorMesh_SpinnCenter")
	UIslandRedBlueImpactCounterResponseComponent ResponseComponent;

	UPROPERTY(DefaultComponent, Attach = "VaultDoorMesh_SpinnCenter")
	UIslandRedBlueTargetableComponent TargetComponent;

	UPROPERTY()
	FIslandVaultDoor_OnCenterPieceShot CenterPieceShot; 

	UPROPERTY()
	FIslandVaultDoor_Event CenterPieceUnlocked;

	UPROPERTY()
	FIslandVaultDoor_Event DoorOpen;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	UMaterialInterface MaterialCenterPieceNotShootable;

	UPROPERTY()
	UMaterialInterface MaterialCenterPieceShootable;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandStormdrainBankVaultDoor_LockBeam> AllLockBeams;

	FLinearColor DefaultColorVaultCenter;

	UPROPERTY()
	FHazeTimeLike TL_RotateCenter;	
	default TL_RotateCenter.Duration = 1.0;
	default TL_RotateCenter.Curve.AddDefaultKey(0.0, 0.0);
	default TL_RotateCenter.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	private UMaterialInstanceDynamic DynamicMaterial;
	float TargetEmissiveMultiplier;

	UPROPERTY()
	FHazeTimeLike TL_OpenDoor;
	default TL_OpenDoor.Duration = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Beam : AllLockBeams)
		{
			if(Beam != nullptr)
			{
				Beam.AttachToComponent(Hinge, NAME_None, EAttachmentRule::KeepWorld);
				Beam.BeamUnlockedDelegate.AddUFunction(this, n"OnBeamUnlocked");
				Beam.BeamLockedDelegate.AddUFunction(this, n"OnBeamLocked");
			}
		}

		VaultDoorMesh_SpinnCenter.SetMaterial(1, MaterialCenterPieceShootable);
		DynamicMaterial = VaultDoorMesh_SpinnCenter.CreateDynamicMaterialInstance(1, VaultDoorMesh_SpinnCenter.GetMaterial(1), NAME_None);
		DefaultColorVaultCenter = DynamicMaterial.GetVectorParameterValue(n"EmissiveColor");
		VaultDoorMesh_SpinnCenter.SetMaterial(1, MaterialCenterPieceNotShootable);

		TL_RotateCenter.BindUpdate(this, n"TL_RotateCenter_Update");
		TL_RotateCenter.BindFinished(this, n"TL_RotateCenter_Finished");

		TL_OpenDoor.BindUpdate(this, n"TL_OpenDoor_Update");
		TL_OpenDoor.BindFinished(this, n"TL_OpenDoor_Finished");

		ResponseComponent.OnImpactEvent.AddUFunction(this, n"OnImpact");
		// ResponseComponent.OnFullAlpha.AddUFunction(this, n"OnFullAlpha");

		TargetComponent.Disable(this);
		
		ResponseComponent.BlockImpactForPlayer(Game::GetMio(), this);
		ResponseComponent.BlockImpactForPlayer(Game::GetZoe(), this);
	}

	UFUNCTION()
	void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		TargetEmissiveMultiplier = 0;
		SetActorTickEnabled(true);
		UStormdrainBankVaultDoorEventHandler::Trigger_OnDoorActivate(this);
		float Progress = (ResponseComponent.GetImpactAlpha(Game::GetMio()) + ResponseComponent.GetImpactAlpha(Game::GetZoe()))/2;
		CenterPieceShot.Broadcast(Progress);
		CheckAlpha();

		//PrintToScreen("MioAlpha: "+ResponseComponent.GetImpactAlpha(Game::GetMio()), 2.0, FLinearColor::Green);
		//PrintToScreen("ZoeAlpha: "+ResponseComponent.GetImpactAlpha(Game::GetZoe()), 2.0, FLinearColor::LucBlue);
	}

	UFUNCTION()
	void CheckAlpha()
	{
		if(ResponseComponent.GetImpactAlpha(Game::GetMio())+ResponseComponent.GetImpactAlpha(Game::GetZoe()) >= 2)
		{
			TL_OpenDoor.Play();
			OpenDoorStarted();

			ResponseComponent.BlockImpactForPlayer(Game::GetZoe(), this);
			ResponseComponent.BlockImpactForPlayer(Game::GetMio(), this);

			VaultDoorMesh_SpinnCenter.SetMaterial(1, MaterialCenterPieceNotShootable);
			TargetComponent.Disable(this);
		}
	}

	// UFUNCTION()
	// void OnFullAlpha(AHazePlayerCharacter Player)
	// {
		
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(TargetEmissiveMultiplier != 3)
		{
			TargetEmissiveMultiplier = Math::FInterpConstantTo(TargetEmissiveMultiplier, 1, DeltaSeconds, 5);
			DynamicMaterial.SetVectorParameterValue(n"EmissiveColor", DefaultColorVaultCenter*TargetEmissiveMultiplier);

			if(Math::IsNearlyEqual(TargetEmissiveMultiplier, 1, SMALL_NUMBER))
			{
				TargetEmissiveMultiplier = 1;
				DynamicMaterial.SetVectorParameterValue(n"EmissiveColor", DefaultColorVaultCenter);
				SetActorTickEnabled(false);
				UStormdrainBankVaultDoorEventHandler::Trigger_OnDoorDeactivate(this);
			}
		}

	}

	UFUNCTION()
	void SetMaterialShootable()
	{
		VaultDoorMesh_SpinnCenter.SetMaterial(1, DynamicMaterial);
	}

	UFUNCTION()
	void TL_RotateCenter_Update(float CurveValue)
	{
		VaultDoorMesh_SpinnCenter.SetRelativeRotation(FRotator(0, 0, CurveValue*-540));
		UStormdrainBankVaultDoorEventHandler::Trigger_OnRotateCenterUpdate(this);
	}

	UFUNCTION()
	void TL_RotateCenter_Finished()
	{
		ResponseComponent.UnblockImpactForPlayer(Game::GetMio(), this);
		ResponseComponent.UnblockImpactForPlayer(Game::GetZoe(), this);

		SetMaterialShootable();
		
		TargetComponent.Enable(this);

		UStormdrainBankVaultDoorEventHandler::Trigger_OnRotateCenterFinished(this);
	}
	
	UFUNCTION()
	void TL_OpenDoor_Update(float CurveValue)
	{
		Hinge.SetRelativeRotation(FRotator(0,CurveValue*-90,0));
		UStormdrainBankVaultDoorEventHandler::Trigger_OnOpenDoorUpdate(this);
	}

	UFUNCTION()
	void TL_OpenDoor_Finished()
	{
		UStormdrainBankVaultDoorEventHandler::Trigger_OnOpenDoorFinished(this);
		OpenDoorFinished();
		DoorOpen.Broadcast();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenDoorStarted() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenDoorFinished() { }

	UFUNCTION()
	void OnBeamLocked(AIslandStormdrainBankVaultDoor_LockBeam Beam)
	{
		auto BeamEventData = FStormdrainBankVaultDoorEventData(Beam);
		UStormdrainBankVaultDoorEventHandler::Trigger_BeamLocked(this, BeamEventData);
	}

	UFUNCTION()
	void OnBeamUnlocked(AIslandStormdrainBankVaultDoor_LockBeam Beam)
	{
		auto BeamEventData = FStormdrainBankVaultDoorEventData(Beam);
		UStormdrainBankVaultDoorEventHandler::Trigger_OnBeamUnlocked(this, BeamEventData);
		BeamUnlocked(BeamEventData);
		if(IsAllBeamsUnlocked())
		{
			TL_RotateCenter.Play();
			UStormdrainBankVaultDoorEventHandler::Trigger_OnFinalBeamUnlocked(this, BeamEventData);
			FinalBeamUnlocked(BeamEventData);
			CenterPieceUnlocked.Broadcast();
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinalBeamUnlocked(FStormdrainBankVaultDoorEventData BeamData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamUnlocked(FStormdrainBankVaultDoorEventData BeamData) {}

	UFUNCTION()
	bool IsAllBeamsUnlocked()
	{
		for(auto Beam : AllLockBeams)
		{
			if(Beam == nullptr)
			{
				return false;
			}
			if(Beam.State != EIslandBankVaultDoorState::Unlocked)
			{
				return false;
			}
		}
		return true;
	}

	UFUNCTION()
	int GetNumBeamsUnlocked() const
	{
		int NumUnlocked = 0;
		for(auto IterBeam : AllLockBeams)
		{
			if(IterBeam == nullptr || IterBeam.State == EIslandBankVaultDoorState::Unlocked)
			{
				NumUnlocked++;
			}
		}
		return NumUnlocked;
	}

	UFUNCTION()
	int GetNumBeamsLocked() const
	{
		int NumLocked = 0;
		for(auto IterBeam : AllLockBeams)
		{
			if(IterBeam != nullptr && IterBeam.State == EIslandBankVaultDoorState::Locked)
			{
				NumLocked++;
			}
		}
		return NumLocked;
	}

	UFUNCTION()
	int GetNumBeamsShootable() const
	{
		int NumShootable = 0;
		for(auto IterBeam : AllLockBeams)
		{
			if(IterBeam != nullptr && IterBeam.State == EIslandBankVaultDoorState::Shootable)
			{
				NumShootable++;
			}
		}
		return NumShootable;
	}

}