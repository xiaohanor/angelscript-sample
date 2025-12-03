event void FIslandShootablePanelEvent();

enum EIslandPanelType
{
	Grounded, 
	WallMounted_A,
	WallMounted_B,
	WallMounted_TwoSides
};

struct FIslandPanelData
{
	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	TArray<int> MaterialSlots;

	UPROPERTY()
	FVector TargetOffset;
}

class AIslandShootablePanel : AHazeActor
{
	UPROPERTY()
	FIslandShootablePanelEvent OnDisabled;

	UPROPERTY()
	FIslandShootablePanelEvent OnEnabled;

	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UIslandRedBlueImpactShieldResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = "ImpactComp")
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings ZoeSettings;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface ShotMaterial;

	UPROPERTY()
	UMaterialInterface DeactivatedMaterial;

	UMaterialInterface Material;

	TArray<int> MaterialSlots;

	float ResetMaterialTimer = 0;
	float MaxResetMaterialTimer = 0.1;
	
	UPROPERTY(EditInstanceOnly)
	bool bActive = true;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TMap<EIslandPanelType, FIslandPanelData> Map;

	UPROPERTY(EditInstanceOnly)
	EIslandPanelType PanelType;

	UPROPERTY(EditInstanceOnly)
	bool bAutomaticallyReenable = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bAutomaticallyReenable", EditConditionHides))
	float ReenableAfterDuration = 5; 

	float AutoReenableTimer = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetStaticMesh(Map.FindOrAdd(PanelType).Mesh);
		MaterialSlots = Map.FindOrAdd(PanelType).MaterialSlots;

		int MaterialCount = Mesh.NumMaterials;
		for (int i = 0; i < MaterialCount; i++)
		{
			Mesh.SetMaterial(i, Mesh.StaticMesh.GetMaterial(i));
		}

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			Material = MioMaterial;
			ImpactComp.Settings = MioSettings;
		}
		else
		{
			Material = ZoeMaterial;
			ImpactComp.Settings = ZoeSettings;
		}

		if(bActive)
			SetMaterial(Material);
		else
			SetMaterial(DeactivatedMaterial);
		ImpactComp.SetRelativeLocation(Map.FindOrAdd(PanelType).TargetOffset);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnImpactOnShield.AddUFunction(this, n"HandleImpact");
		ImpactComp.OnImpactWhenShieldDestroyed.AddUFunction(this, n"HandleFullAlpha");
		
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			Material = MioMaterial;
		}
		else
		{
			Material = ZoeMaterial;
		}

		MaterialSlots = Map.FindOrAdd(PanelType).MaterialSlots;
		UpdateShootComponents();
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		if(bActive)
		{
			SetMaterial(ShotMaterial);
			ResetMaterialTimer = MaxResetMaterialTimer;
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION()
	void DisablePanel()
	{
		bActive = false;
		SetMaterial(DeactivatedMaterial);
		UpdateShootComponents();

		if(bAutomaticallyReenable)
		{
			SetReenableTimer();
		}
	}

	UFUNCTION()
	void HandleFullAlpha(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		DisablePanel();
		
		OnDisabled.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ResetMaterialTimer > 0)
		{
			ResetMaterialTimer -= DeltaSeconds;
			if(ResetMaterialTimer <= 0)
			{
				if(bActive)
				{
					SetMaterial(Material);
				}
			}
		}

		if(bAutomaticallyReenable)
		{
			if(AutoReenableTimer > 0)
			{
				AutoReenableTimer -= DeltaSeconds;
				if(AutoReenableTimer <= 0)
				{
					if(!bActive)
					{
						ResetPanel();
					}
				}
			}
		}
	}

	UFUNCTION()
	void SetCanReenable(bool bCanReenable)
	{
		if(bAutomaticallyReenable == bCanReenable)
			return;

		bAutomaticallyReenable = bCanReenable;
		if(bAutomaticallyReenable && !bActive)
		{
			SetReenableTimer();
		}
	}

	void SetReenableTimer()
	{
		AutoReenableTimer = ReenableAfterDuration;
		SetActorTickEnabled(true);
	}

	void SetMaterial(UMaterialInterface NewMaterial)
	{
		for(int MaterialSlot : MaterialSlots)
		{
			Mesh.SetMaterial(MaterialSlot, NewMaterial);
		}
	}

	UFUNCTION()
	void ResetPanel()
	{
		ImpactComp.ResetShieldAlpha();
		bActive = true;
		SetMaterial(Material);
		UpdateShootComponents();
		ResetMaterialTimer = 0;
		AutoReenableTimer = 0;
		OnEnabled.Broadcast();
	}

	void UpdateShootComponents()
	{
		if(!bActive)
		{
			SetActiveForPlayer(Game::GetZoe(), false);
			SetActiveForPlayer(Game::GetMio(), false);
		}

		else
		{
			if(UsableByPlayer == EHazePlayer::Mio)
			{
				SetActiveForPlayer(Game::GetZoe(), false);
				SetActiveForPlayer(Game::GetMio(), true);
			}
			else
			{
				SetActiveForPlayer(Game::GetZoe(), true);
				SetActiveForPlayer(Game::GetMio(), false);
			}
		}
	}

	void SetActiveForPlayer(AHazePlayerCharacter Player, bool NewActive)
	{
		if(Player == nullptr)
			return;

		if(NewActive)
		{
			ImpactComp.UnblockImpactForPlayer(Player, this);
			TargetComp.EnableForPlayer(Player, this);
		}

		else
		{
			ImpactComp.BlockImpactForPlayer(Player, this);
			TargetComp.DisableForPlayer(Player, this);
		}
	}
}