event void FIslandSidescrollerMovablePlatformShootPanelEvent(AIslandSidescrollerMovablePlatformShootPanel Panel);

UCLASS(Abstract)
class AIslandSidescrollerMovablePlatformShootPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UIslandRedBlueImpactOverchargeResponseDisplayComponent Display;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Arrow1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Arrow2;

	UPROPERTY()
	FIslandSidescrollerMovablePlatformShootPanelEvent OnStartMovePlatform;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MainMioMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MainZoeMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMioMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveZoeMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface DisabledMaterial;

	UPROPERTY(EditAnywhere)
	EHazePlayer UsableByPlayer;

	UPROPERTY(EditAnywhere)
	bool bRight = true;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel Panel;

	const FRotator RightArrowRotation = FRotator(-45.0, 180.0, 180.0);
	const FRotator LeftArrowRotation = FRotator(135.0, 180.0, 180.0);
	int QueuedUpMoves = 0;
	AIslandSidescrollerMovablePlatform Platform;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetMaterial(0, GetMainMaterial());
		SetMaterialForArrows(GetEmissiveMaterial());
		if(Panel != nullptr)
		{
			Panel.UsableByPlayer = UsableByPlayer;
			Panel.RerunConstructionScripts();
		}

		if(bRight)
		{
			Arrow1.RelativeRotation = RightArrowRotation;
			Arrow2.RelativeRotation = RightArrowRotation;
			Display.RelativeLocation = FVector(-30.0, Display.RelativeLocation.Y, Display.RelativeLocation.Z);
		}
		else
		{
			Arrow1.RelativeRotation = LeftArrowRotation;
			Arrow2.RelativeRotation = LeftArrowRotation;
			Display.RelativeLocation = FVector(30.0, Display.RelativeLocation.Y, Display.RelativeLocation.Z);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::GetPlayer(UsableByPlayer));

		Panel.OverchargeComp.SetDisplayComponent(Display, false);
		Display.CompletedMaterial = Panel.OptionalDisplayCompletedMaterial;
		Panel.OnOvercharged.AddUFunction(this, n"OnOvercharged");
	}

	void SetPlatform(AIslandSidescrollerMovablePlatform In_Platform)
	{
		Platform = In_Platform;
		Platform.OnMoveCompleted.AddUFunction(this, n"OnMoveCompleted");
	}

	UFUNCTION()
	private void OnOvercharged()
	{
		if(!HasControl())
			return;

		NetOnOvercharged();
	}

	UFUNCTION(NetFunction)
	private void NetOnOvercharged()
	{
		OnStartMovePlatform.Broadcast(this);
	}

	UFUNCTION()
	private void OnMoveCompleted(AIslandSidescrollerMovablePlatformShootPanel In_Panel)
	{
		if(In_Panel != this)
			return;
	}

	void UpdateArrowMaterials()
	{
		UStaticMeshComponent A = bRight ? Arrow1 : Arrow2;
		UStaticMeshComponent B = bRight ? Arrow2 : Arrow1;

		SetMaterialForArrow(A, QueuedUpMoves >= 1 ? GetEmissiveMaterial() : DisabledMaterial);
		SetMaterialForArrow(B, QueuedUpMoves >= 2 ? GetEmissiveMaterial() : DisabledMaterial);
	}

	void SetMaterialForArrows(UMaterialInterface Material)
	{
		SetMaterialForArrow(Arrow1, Material);
		SetMaterialForArrow(Arrow2, Material);
	}

	void SetMaterialForArrow(UStaticMeshComponent Arrow, UMaterialInterface Material)
	{
		for(int i = 0; i < Arrow.NumMaterials; i++)
		{
			Arrow.SetMaterial(i, Material);
		}
	}

	UMaterialInterface GetMainMaterial() const
	{
		if(UsableByPlayer == EHazePlayer::Mio)
			return MainMioMaterial;

		return MainZoeMaterial;
	}

	UMaterialInterface GetEmissiveMaterial() const
	{
		if(UsableByPlayer == EHazePlayer::Mio)
			return EmissiveMioMaterial;

		return EmissiveZoeMaterial;
	}
}