// Utility to set a specific bit (8 bit int)
int SetBit(int Number, bool Value, uint Index)
{
	int result = Number;
    if(Value)
	{
        result = Number | (1 << Index);
	}
    else
	{
        result = Number & ~(1 << Index);
	}
	return result;
}

enum ETimeWarStencilState
{
	Nothing,
	State1, // Idle
	State2, // Gravity Puck
	State3, // Stasis Puck
	State4, // Both Puck Types
	State5,
	State6,
	State7,
};

UFUNCTION(BlueprintPure)
int StencilSetTimeWarpNew(int CurrentStencil, int State)
{
	// Feed a two-bit number to the shader.
	int NewStencil = CurrentStencil;
	if(State == 0) // 000
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, false, 5);
		NewStencil = SetBit(NewStencil, false, 6);
	}
	else if(State == 1) // 001
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, false, 5);
		NewStencil = SetBit(NewStencil, true, 6);
	}
	else if(State == 2) // 010
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, true, 5);
		NewStencil = SetBit(NewStencil, false, 6);
	}
	else if(State == 3) // 011
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, true, 5);
		NewStencil = SetBit(NewStencil, true, 6);
	}
	else if(State == 4) // 100
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, false, 5);
		NewStencil = SetBit(NewStencil, false, 6);
	}
	else if(State == 5) // 101
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, false, 5);
		NewStencil = SetBit(NewStencil, true, 6);
	}
	else if(State == 6) // 110
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, true, 5);
		NewStencil = SetBit(NewStencil, false, 6);
	}
	else if(State == 7) // 111
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, true, 5);
		NewStencil = SetBit(NewStencil, true, 6);
	}
	return NewStencil;
}

UFUNCTION()
void SetDebugTexture(UTextureRenderTarget2D Target, int Index)
{
	for(AHazePlayerCharacter Player : Game::GetPlayers())
	{
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::GetOrCreate(Player);
		PostProcessComp.UberShaderMaterialDynamic.SetTextureParameterValue(FName("Debug"+Index+"_Texture"), Target);
		PostProcessComp.UberShaderMaterialDynamic.SetScalarParameterValue(FName("Debug"+Index+"_Enabled"), 1.0f);
	}
}

UFUNCTION()
void SetTimewarp(UPrimitiveComponent Mesh, ETimeWarStencilState State)
{
	if(Mesh != nullptr)
	{
		int NewStencilValue = StencilSetTimeWarpNew(Mesh.CustomDepthStencilValue, int(State));
		if(NewStencilValue != Mesh.CustomDepthStencilValue)
		{
			Mesh.CustomDepthStencilValue = NewStencilValue;
			Mesh.SetRenderCustomDepth(Mesh.CustomDepthStencilValue != 0);
			Mesh.MarkRenderStateDirty();
		}
	}
}

namespace SpeedEffect
{
	UFUNCTION()
	void RequestSpeedEffect(AHazePlayerCharacter Player, float Value, FInstigator Instigator, EInstigatePriority Priority, float Speed = 1.0, bool bUsePlayerMovement = true)
	{
		if (Player == nullptr)
			return;

		UPostProcessingComponent SpeedEffectComp = UPostProcessingComponent::GetOrCreate(Player);

		if (SpeedEffectComp == nullptr)
			return;

		FSpeedEffect Effect;
		Effect.Strength = Value;
		Effect.Speed = Speed;
		Effect.bUsePlayerMovement = bUsePlayerMovement;
		SpeedEffectComp.CurrentSpeedEffect.Apply(Effect, Instigator, Priority);
		DevMenu::RequestTransientDevMenu(n"Speed Effect", "🌬️", USpeedEffectDevMenu);
	}
	UFUNCTION()
	void ClearSpeedEffect(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player == nullptr)
			return;

		UPostProcessingComponent SpeedEffectComp = UPostProcessingComponent::GetOrCreate(Player);

		if (SpeedEffectComp == nullptr)
			return;
		
		SpeedEffectComp.CurrentSpeedEffect.Clear(Instigator);
	}
}

namespace PostProcessing
{
	UFUNCTION()
	UMaterialInstanceDynamic ApplyPostProcessMaterial(AHazePlayerCharacter Player, UMaterialInterface Material, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		if (Player == nullptr)
			return nullptr; 
		UMaterialInstanceDynamic mat = Material::CreateDynamicMaterialInstance(nullptr, Material);
		UPostProcessingComponent::Get(Player).ApplyPostProcess(mat, Instigator, Priority);
		return mat;
	}

	UFUNCTION()
	void ClearPostProcessMaterial(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent::Get(Player).ClearPostProcess(Instigator);
	}

	UFUNCTION()
	UNiagaraComponent GetCameraParticles(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return nullptr; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		return PostProcessComp.CameraParticlesComponent;
	}

	UFUNCTION()
	UNiagaraComponent ApplyCameraParticles(
		AHazePlayerCharacter Player,
		UNiagaraSystem Value,
		FInstigator Instigator,
		EInstigatePriority Priority,
		FVector LocalOffset = FVector::ZeroVector,
		bool bRegisterWithKillParticlesVolumeManager = false
	)
	{
		if (Player == nullptr)
			return nullptr; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);

		PostProcessComp.ApplyCameraParticles(Value, Instigator, Priority, LocalOffset);

		if(bRegisterWithKillParticlesVolumeManager)
		{
			KillParticleManager::RegisterNiagaraComponent(PostProcessComp.CameraParticlesComponent);
		}

		return PostProcessComp.CameraParticlesComponent;
	}

	UFUNCTION()
	void ClearCameraParticles(AHazePlayerCharacter Player, FInstigator Instigator, bool bDeactivateImmediately = false)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.ClearCameraParticles(Instigator, bDeactivateImmediately);
		KillParticleManager::UnregisterNiagaraComponent(PostProcessComp.CameraParticlesComponent);
	}

	UFUNCTION()
	void TestInfluencePointsWithPlayer(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.TestWithPlayer(Player);
	}

	void AddInfluencePointsForMesh(UHazeSkeletalMeshComponentBase Mesh)
	{
		// ugly redirect for now. Need to fix where it is used and then fix this.
		InfluenceSystem::AddPointsForMeshBones(Mesh);
	}

	void RemoveInfluencePointsForMesh(UHazeSkeletalMeshComponentBase Mesh)
	{
		// ugly redirect for now. Need to fix where it is used and then fix this.
		InfluenceSystem::RemovePointsForComp(Mesh);
		// RemoveInfluencePointsForMeshForPlayer(Game::GetMio(), Mesh);
		// RemoveInfluencePointsForMeshForPlayer(Game::GetZoe(), Mesh);
	}

	void RemoveInfluencePointsForMeshForPlayer(AHazePlayerCharacter Player, UHazeSkeletalMeshComponentBase Mesh)
	{
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.RemovePointsForComp(Mesh);
	}

	UFUNCTION()
	void AddInfluencePoint(AHazePlayerCharacter Player, FNiagaraInfluencePoint Point)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.AddPoint(Point);
	}

	UFUNCTION()
	void ClearAllInfluencePoints(AHazePlayerCharacter Player, FNiagaraInfluencePoint Point)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.ResetAllPoints();
	}

	UFUNCTION()
	void AddInfluenceActor(AActor Actor)
	{
		AddInfluenceActorTo(Game::GetMio(), Actor);
		AddInfluenceActorTo(Game::GetZoe(), Actor);
	}

	UFUNCTION()
	void RemoveInfluenceActor(AActor Actor)
	{
		RemoveInfluenceActorFrom(Game::GetMio(), Actor);
		RemoveInfluenceActorFrom(Game::GetZoe(), Actor);
	}

	void AddInfluenceActorTo(AHazePlayerCharacter Player, AActor Actor)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.AddSourceActor(Actor);
	}

	void RemoveInfluenceActorFrom(AHazePlayerCharacter Player, AActor Actor)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.CameraParticlesInfluence.RemoveSourceActor(Actor);
	}

	void SetVignetteOpacity(AHazePlayerCharacter Player, float Opacity, float BlendTime)
	{
		if (Player == nullptr)
			return; 
		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.SetVignetteOpacity(Opacity, BlendTime);
	}

	UFUNCTION()
	void OverExposeToWhite(AHazePlayerCharacter Player, float BlendTime = 2.0)
	{
		if (Player == nullptr)
			return; 
 		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.SetAutoExposureBias(15.0, BlendTime);
	}

	// Note that there is an inherent delay in clearing over exposure 
	UFUNCTION()
	void ClearOverExposure(AHazePlayerCharacter Player, float StartBlendTime = 0.0)
	{
		if (Player == nullptr)
			return;
 		UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Player);
		PostProcessComp.ClearAutoExposureBias(StartBlendTime);
	}
}

struct FSpeedEffect
{
	float Strength;
	float Speed;
	bool bUsePlayerMovement;
}

class UPostProcessingComponent : UActorComponent
{
	TInstigated<UMaterialInterface> PostProcessMaterial;
	TInstigated<UNiagaraSystem> CurrentCameraParticles;

	FNiagaraInfluence CameraParticlesInfluence;

	UPROPERTY()
	UNiagaraComponent CameraParticlesComponent;
	FVector CameraParticlesComponentOffset = FVector::ZeroVector;

	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	UPROPERTY()
	UNiagaraParameterCollection GlobalNiagaraParameters;
	UNiagaraParameterCollectionInstance GlobalNiagaraParams_Inst;

	UPROPERTY()
	UOutlineViewerComponent OutlinesComponent;

	UPROPERTY()
	UStencilEffectViewerComponent StencilEffectViewerComponent;

	FPostProcessSettings GlobalPostProcess;
	
	TInstigated<FSpeedEffect> CurrentSpeedEffect;
	TInstigated<float> BlackAndWhiteStrength;
	TInstigated<bool> UberShaderEnablement;

    UPROPERTY()
	float GasStrength = 0.0;

    UPROPERTY(EditAnywhere)
    UMaterialInterface UberShaderMaterial;

    UPROPERTY(EditAnywhere)
    UMaterialInterface BlackAndWhitePostProcessMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic UberShaderMaterialDynamic;

	UPROPERTY()
	bool bOverridePlayerPosition;
	UPROPERTY()
	FVector OverridePlayerPosition;
	UPROPERTY()
	FVector OverridePlayerVelocity;

	UPROPERTY()
	UMaterialParameterCollection StencilParameters;

	private UMaterialInstanceDynamic BlackAndWhiteDynamicMaterial;
	private float AppliedBlackAndWhiteStrength = 0.0;

	private FHazeAcceleratedFloat CurrentVignetteOpacity;
	private float TargetVignetteOpacity = 1.0;
	private float VignetteBlendTime = 0.0;

	private FHazeAcceleratedFloat CurrentAutoExposureBias;
	private float TargetAutoExposureBias = 1.0;
	private float AutoExposureBiasBlendTime = 0.0;

	UFUNCTION()
	void ApplyCameraParticles(UNiagaraSystem Value, FInstigator Instigator, EInstigatePriority Priority, FVector LocalOffset = FVector::ZeroVector)
	{
		// clear any previous ones. We only allow one at a time for now. 
		CurrentCameraParticles.Clear(CurrentCameraParticles.GetCurrentInstigator());

		CurrentCameraParticles.Apply(Value, Instigator, Priority);
		SetCameraParticles(CurrentCameraParticles.Get());
		CameraParticlesComponentOffset = LocalOffset;
	}

	UFUNCTION()
	void ClearCameraParticles(FInstigator instigator, bool bDeactivateImmediately = false)
	{
		CameraParticlesComponentOffset = FVector::ZeroVector;

		// clear the entire thing, since we only allow one to be active at a time
		CurrentCameraParticles.Clear(CurrentCameraParticles.GetCurrentInstigator());

		auto DebugPtr = CurrentCameraParticles.Get();

#if EDITOR
		devCheck(DebugPtr == nullptr);
#endif

		SetCameraParticles(DebugPtr);

		if(bDeactivateImmediately && CameraParticlesComponent != nullptr)
		{
			CameraParticlesComponent.DeactivateImmediate();
		}

	}
	
	void SetCameraParticles(UNiagaraSystem Value)
	{
		// Destroy or fade out the current effect if it exists.
		if(CameraParticlesComponent != nullptr)
		{
			if(Value != nullptr)
			{
				// nuke the previous effect
				CameraParticlesComponent.DeactivateImmediate();
				if(CameraParticlesComponent != nullptr)
				{
					CameraParticlesComponent.DestroyComponent(CameraParticlesComponent);
				}
				CameraParticlesComponent = nullptr;
			}
			else
			{
				// soft deactivate. Lets particles finish their lifetime. 
				CameraParticlesComponent.Deactivate();
			}
		}

		CameraParticlesInfluence.Reset();
		
		// Spawn a new effect.
		if(Value != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);

			CameraParticlesComponent = UNiagaraComponent::Create(Game::DynamicSpawnWorldSettings);
			CameraParticlesComponent.SetAsset(Value);
			CameraParticlesComponent.Activate(true);

			CameraParticlesInfluence.Init(CameraParticlesComponent);

			// Make visible only on one players screen.
			if(Player != nullptr)
			{
				CameraParticlesComponent.SetRenderedForPlayer(Player, true);
				CameraParticlesComponent.SetRenderedForPlayer(Player.OtherPlayer,false);
			}
		}
	}

	void ApplyPostProcess(UMaterialInterface Material, FInstigator Instigator, EInstigatePriority Priority)
	{
		PostProcessMaterial.Apply(Material, Instigator, Priority);
		UpdatePostProcess();
	}

	void ClearPostProcess(FInstigator Instigator)
	{
		PostProcessMaterial.Clear(Instigator);
		UpdatePostProcess();
	}
	
	void UpdatePostProcess()
	{
		GlobalPostProcess.WeightedBlendables.Array.Reset();

		bool bEnableUberShader = false;
		if (UberShaderEnablement.Get() == true)
			bEnableUberShader = true;
		if (CurrentSpeedEffect.Get().Strength > 0)
			bEnableUberShader = true;

		if (bEnableUberShader)
		{
			FWeightedBlendable Blendable;
			Blendable.Object = UberShaderMaterialDynamic;
			Blendable.Weight = 1.0;
			GlobalPostProcess.WeightedBlendables.Array.Add(Blendable);
		}

		if (PostProcessMaterial.Get() != nullptr)
		{
			FWeightedBlendable Blendable;
			Blendable.Object = PostProcessMaterial.Get();
			Blendable.Weight = 1.0;
			GlobalPostProcess.WeightedBlendables.Array.Add(Blendable);
		}

		GlobalPostProcess.AmbientCubemapIntensity = 0;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		Player.AddCustomPostProcessSettings(GlobalPostProcess, 1.0, this);
	}

	void SetVignetteOpacity(float Opacity, float BlendTime)
	{
		TargetVignetteOpacity = Opacity;
		VignetteBlendTime = BlendTime;
	}

	void SetAutoExposureBias(float Exposure, float BlendTime)
	{
		TargetAutoExposureBias = Exposure;
		AutoExposureBiasBlendTime = BlendTime;
	}
	
	void ClearAutoExposureBias(float BlendTime)
	{
		TargetAutoExposureBias = 1.0;
		AutoExposureBiasBlendTime = BlendTime;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        UberShaderMaterialDynamic = Material::CreateDynamicMaterialInstance(nullptr, UberShaderMaterial);
		// Gets used directly by the render thread, so we can't remove it ever
		UberShaderMaterialDynamic.AddToRoot();

		FWeightedBlendable Blendable;
		Blendable.Object = UberShaderMaterialDynamic;
		Blendable.Weight = 1.0;
		GlobalPostProcess.WeightedBlendables.Array.Add(Blendable);
		GlobalPostProcess.AmbientCubemapIntensity = 0;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		Player.AddCustomPostProcessSettings(GlobalPostProcess, 1.0, this);

		UStencilEffectViewerComponent::Get(Owner).Init();

		GlobalNiagaraParams_Inst = Niagara::GetNiagaraParameterCollection(GlobalNiagaraParameters);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (CameraParticlesComponent != nullptr)
		{
			CameraParticlesComponent.DestroyComponent(CameraParticlesComponent);
			CameraParticlesComponent = nullptr;
		}
	}

	FQuat PreviousViewQuat;

	float SpeedEffectLeftRight = 0;
	float SpeedEffectLeftRightTarget = 0;
	float SpeedEffectTime = 0;
	float SpeedEffectStrength = 0;
	float SpeedEffectSpeed = 0;
	
	void SetPostProcessEnabled(bool bEnabled)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		Player.RemoveCustomPostProcessSettings(this);
		if(bEnabled)
		{
			FWeightedBlendable Blendable;
			Blendable.Object = UberShaderMaterialDynamic;
			Blendable.Weight = 1.0;
			GlobalPostProcess.WeightedBlendables.Array.Add(Blendable);
			GlobalPostProcess.AmbientCubemapIntensity = 0;
			Player.AddCustomPostProcessSettings(GlobalPostProcess, 1.0, this);
		}
		
	}
	
	FVector AccumulatedVelocity = FVector(0,0,0);
	FLinearColor Player0Position = FLinearColor(0,0,0,0);
	FLinearColor Player1Position = FLinearColor(0,0,0,0);
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"ViewportIndex", int(Player.Player));

		UberShaderMaterialDynamic.SetScalarParameterValue(n"gasData_Strength", GasStrength);

		FVector CameraSpaceSpeedEffectDirection = FVector(0,0,0);
		FVector SpeedEffectDirection = FVector(0,0,0);
		
		// Speed Shimmer
		if(Player != nullptr)
		{
			// Global player shader location, used for various effects such as bushes moving out of the way.
			FVector PlayerLocation = Player.GetActorLocation();
			if(bOverridePlayerPosition)
				AccumulatedVelocity += OverridePlayerVelocity;
			else 
				AccumulatedVelocity += Player.GetActorVelocity();

			AccumulatedVelocity = Math::Lerp(AccumulatedVelocity, FVector::ZeroVector, Math::Clamp(DeltaTime * 4.0, 0.0, 1.0));
			float FinalPlayerVelocity = AccumulatedVelocity.Size() / 3000.0;
			
			if(Player.CurrentlyUsedCamera != nullptr)
			{
				SpeedEffectDirection = Player.ActorVelocity;
				SpeedEffectDirection.Normalize();

				CameraSpaceSpeedEffectDirection = Player.ViewTransform.InverseTransformVector(SpeedEffectDirection);
			}

			if(CameraParticlesComponent != nullptr)
			{
				CameraParticlesComponent.WorldTransform = Player.ViewTransform;
				CameraParticlesComponent.AddLocalOffset(CameraParticlesComponentOffset);
				CameraParticlesInfluence.Tick(DeltaTime);
			}
			
			const FQuat CurrentViewQuat = Player.ViewRotation.Quaternion();
			const float AngleDelta = PreviousViewQuat.AngularDistance(CurrentViewQuat);
			PreviousViewQuat = CurrentViewQuat;

			//if(Player.bIsParticipatingInCutscene)
			//{
				Player.Mesh.SetScalarParameterValueOnMaterials(n"HazeToggleCategory_DitherNearFade_Enabled", 0);
				Player.Mesh.SetScalarParameterValueOnMaterials(n"DitherNearFade_Range", 250);
			//}
			//else
			//{
			//	Player.Mesh.SetScalarParameterValueOnMaterials(n"HazeToggleCategory_DitherNearFade_Enabled", 1);
			//	Player.Mesh.SetScalarParameterValueOnMaterials(n"DitherNearFade_Range", 250);
			//}

			if(Player == Game::GetMio())
			{
				if(bOverridePlayerPosition)
					Material::SetVectorParameterValue(GlobalParameters, n"Player0Position", FLinearColor(OverridePlayerPosition, FinalPlayerVelocity));
				else
					Material::SetVectorParameterValue(GlobalParameters, n"Player0Position", FLinearColor(Player.GetActorLocation(), FinalPlayerVelocity));

				Material::SetVectorParameterValue(GlobalParameters, n"Player0PositionPrev", Player0Position);
				if(bOverridePlayerPosition)
					Player0Position = FLinearColor(OverridePlayerPosition, FinalPlayerVelocity);
				else
					Player0Position = FLinearColor(Player.GetActorLocation(), FinalPlayerVelocity);
				Material::SetVectorParameterValue(GlobalParameters, n"Player0HipsPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"Hips"), 0));

				Material::SetVectorParameterValue(GlobalParameters, n"Player0LeftFootPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"LeftFoot"), 0));
				Material::SetVectorParameterValue(GlobalParameters, n"Player0RightFootPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"RightFoot"), 0));

				Material::SetScalarParameterValue(GlobalParameters, n"Player0CameraDeltaAngle", AngleDelta);
				Material::SetVectorParameterValue(GlobalParameters, n"Player0CameraPosition", FLinearColor(Player.ViewTransform.GetLocation()));

				Material::SetScalarParameterValue(GlobalParameters, n"Player0IsParticipatingInCutscene", Player.bIsParticipatingInCutscene ? 1 : 0);

				GlobalNiagaraParams_Inst.SetPositionParameter("Mio_WorldPos", Player.GetActorLocation());	
				GlobalNiagaraParams_Inst.SetPositionParameter("Mio_CameraPos", Player.ViewTransform.Location);	
				GlobalNiagaraParams_Inst.SetVectorParameter("Mio_CameraFwd", Player.ViewTransform.GetRotation().Vector());	
				GlobalNiagaraParams_Inst.SetVectorParameter("Mio_Velocity", Player.ActorVelocity);	
			}
			else
			{
				if(bOverridePlayerPosition)
					Material::SetVectorParameterValue(GlobalParameters, n"Player1Position", FLinearColor(OverridePlayerPosition, FinalPlayerVelocity));
				else
					Material::SetVectorParameterValue(GlobalParameters, n"Player1Position", FLinearColor(Player.GetActorLocation(), FinalPlayerVelocity));
				Material::SetVectorParameterValue(GlobalParameters, n"Player1PositionPrev", Player1Position);
				if(bOverridePlayerPosition)
					Player1Position = FLinearColor(OverridePlayerPosition, FinalPlayerVelocity);
				else
					Player1Position = FLinearColor(Player.GetActorLocation(), FinalPlayerVelocity);
				Material::SetVectorParameterValue(GlobalParameters, n"Player1HipsPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"Hips"), 0));

				Material::SetVectorParameterValue(GlobalParameters, n"Player1LeftFootPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"LeftFoot"), 0));
				Material::SetVectorParameterValue(GlobalParameters, n"Player1RightFootPosition", FLinearColor(Player.Mesh.GetSocketLocation(n"RightFoot"), 0));

				Material::SetScalarParameterValue(GlobalParameters, n"Player1CameraDeltaAngle", AngleDelta);
				Material::SetVectorParameterValue(GlobalParameters, n"Player1CameraPosition", FLinearColor(Player.ViewTransform.GetLocation()));
				GlobalNiagaraParams_Inst.SetPositionParameter("Zoe_WorldPos", Player.GetActorLocation());	
				GlobalNiagaraParams_Inst.SetPositionParameter("Zoe_CameraPos", Player.ViewTransform.Location);	
				GlobalNiagaraParams_Inst.SetVectorParameter("Zoe_CameraFwd", Player.ViewTransform.GetRotation().Vector());	
				GlobalNiagaraParams_Inst.SetVectorParameter("Zoe_Velocity", Player.ActorVelocity);	
			}

		}
		
		auto SpeedEffect = CurrentSpeedEffect.Get();
		
		float Backwards = Math::Sign(CameraSpaceSpeedEffectDirection.X + 0.25);

		if(SpeedEffect.bUsePlayerMovement)
		{
			SpeedEffectLeftRightTarget = ((Backwards * CameraSpaceSpeedEffectDirection.Y * 1) + 1.0) * 0.5;
			SpeedEffectTime += DeltaTime * Backwards * SpeedEffectSpeed;
		}
		else
		{
			SpeedEffectLeftRightTarget = 0.5;
			SpeedEffectTime += DeltaTime * SpeedEffectSpeed;
		}

		SpeedEffectSpeed	 = Math::Lerp(SpeedEffectSpeed, 	SpeedEffect.Speed, 			DeltaTime * 2.0);
		SpeedEffectLeftRight = Math::Lerp(SpeedEffectLeftRight, SpeedEffectLeftRightTarget, DeltaTime * 2.0);
		SpeedEffectStrength  = Math::Lerp(SpeedEffectStrength,  SpeedEffect.Strength, 	    DeltaTime * 2.0);

		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"speedEffectData_PosX", SpeedEffectLeftRight);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"speedEffectData_Time", SpeedEffectTime);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"speedEffectData_Strength", SpeedEffectStrength);
		UberShaderMaterialDynamic.SetVectorParameterValue(n"speedEffectData_Color", FLinearColor(1, 1, 1, 1));

		UpdateBlackAndWhiteEffect();
		UpdateVignette(DeltaTime);
		UpdateAutoExposureBias(DeltaTime);
		UpdatePostProcess();
	}

	void UpdateBlackAndWhiteEffect()
	{
		if (BlackAndWhitePostProcessMaterial == nullptr)
			return;

		if (AppliedBlackAndWhiteStrength != BlackAndWhiteStrength.Get())
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
			if (BlackAndWhiteStrength.Get() != 0.0)
			{
				if (BlackAndWhiteDynamicMaterial == nullptr)
				{
					BlackAndWhiteDynamicMaterial = Material::CreateDynamicMaterialInstance(nullptr, BlackAndWhitePostProcessMaterial);
					// Gets used directly by the render thread, so we can't remove it ever
					BlackAndWhiteDynamicMaterial.AddToRoot();
				}

				if (AppliedBlackAndWhiteStrength == 0.0)
				{
					FWeightedBlendable Blendable;
					Blendable.Object = BlackAndWhiteDynamicMaterial;
					Blendable.Weight = 1.0;

					FPostProcessSettings AddedPostProcess;
					AddedPostProcess.WeightedBlendables.Array.Add(Blendable);
					AddedPostProcess.AmbientCubemapIntensity = 0;

					Player.AddCustomPostProcessSettings(AddedPostProcess, 1.0, FInstigator(this, n"BlackAndWhite"));
				}

				BlackAndWhiteDynamicMaterial.SetScalarParameterValue(n"BlackAndWhiteStrength", BlackAndWhiteStrength.Get());
				AppliedBlackAndWhiteStrength = BlackAndWhiteStrength.Get();
			}
			else
			{
				Player.RemoveCustomPostProcessSettings(FInstigator(this, n"BlackAndWhite"));
				AppliedBlackAndWhiteStrength = 0.0;
			}
		}
	}

	void UpdateVignette(float DeltaTime)
	{
		float PrevVignette = CurrentVignetteOpacity.Value;
		CurrentVignetteOpacity.AccelerateTo(TargetVignetteOpacity, VignetteBlendTime, DeltaTime);

		if (PrevVignette != CurrentVignetteOpacity.Value)
		{
			if (CurrentVignetteOpacity.Value == 1.0)
			{
				GlobalPostProcess.bOverride_VignetteIntensity = false;
				GlobalPostProcess.VignetteIntensity = 0.4;
			}
			else
			{
				GlobalPostProcess.bOverride_VignetteIntensity = true;
				GlobalPostProcess.VignetteIntensity = 0.4 * CurrentVignetteOpacity.Value;
			}

			UpdatePostProcess();
		}
	}

	void UpdateAutoExposureBias(float DeltaTime)
	{
		float PrevExposure = CurrentAutoExposureBias.Value;
		CurrentAutoExposureBias.AccelerateTo(TargetAutoExposureBias, AutoExposureBiasBlendTime, DeltaTime);

		if (PrevExposure != CurrentAutoExposureBias.Value)
		{
			if (Math::Abs(CurrentAutoExposureBias.Value - 1.0) < KINDA_SMALL_NUMBER)
			{
				GlobalPostProcess.bOverride_AutoExposureBias = false;
				GlobalPostProcess.AutoExposureBias = 1.0;
			}
			else
			{
				GlobalPostProcess.bOverride_AutoExposureBias = true;
				GlobalPostProcess.AutoExposureBias = CurrentAutoExposureBias.Value;
			}

			UpdatePostProcess();
		}
	}
}
