
// enum ESummitEggBeastVolumeShootState
// {
// 	None,
// 	StartShooting,
// 	StopShooting
// }

class ASummitEggBeastShootVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	ASummitEggStoneBeast EggBeast;

	// UPROPERTY(EditAnywhere)
	// ESummitEggBeastVolumeShootState NewShootState;

	UPROPERTY(DefaultComponent)
	USummitEggBeastShootVolumeEditorRenderedComp EditorRenderedComp;

	// UPROPERTY(DefaultComponent)
	// UTextRenderComponent TextComp;
	// default TextComp.IsVisualizationComponent = true;
	// default TextComp.Text = FText::FromString(f"{NewShootState :n}");
	// default TextComp.bHiddenInGame = true;

	default Shape::SetVolumeBrushColor(this, FLinearColor(0.01, 0.62, 0.70));
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	float ArrowSize = 80;

	UPROPERTY(EditAnywhere)
	float LineThickness = 40;

	UPROPERTY(EditAnywhere)
	FName InstigatorName = n"ShootVolume";

	// UPROPERTY(EditAnywhere)
	// bool bTriggerOnce = true;

	UPROPERTY(EditAnywhere)
	bool bAddPlayerTargetOnEnter = true;

	UPROPERTY(EditAnywhere)
	bool bClearPlayerTargetOnExit = false;

	// UFUNCTION(BlueprintOverride)
	// void ConstructionScript()
	// {
	// 	TextComp.Text = FText::FromString(f"{NewShootState :n}");
	// }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (bClearPlayerTargetOnExit)
			EggBeast.RemovePlayerTargetInstigator(Player, InstigatorName);

		if (EggBeast.GetTotalInstigatorCount() == 0)
			EggBeast.StopShooting();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bAddPlayerTargetOnEnter)
		{
			int StartInstigatorCount = EggBeast.GetTotalInstigatorCount();
			EggBeast.AddPlayerTargetInstigator(Player, InstigatorName);
			if (StartInstigatorCount == 0)
				EggBeast.StartShooting();
		}
	}
};

UCLASS(HideCategories = "Physics Collision Lighting Rendering Navigation Debug Activation Cooking Tags Lod TextureStreaming")
class USummitEggBeastShootVolumeEditorRenderedComp : UHazeEditorRenderedComponent
{
#if EDITOR
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		MarkRenderStateDirty();
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		ASummitEggBeastShootVolume ShootVolume = Cast<ASummitEggBeastShootVolume>(Owner);
		if (ShootVolume.EggBeast == nullptr)
			return;

		SetRenderForeground(true);
		DrawArrow(ShootVolume.ActorLocation, ShootVolume.EggBeast.MuzzleComp.WorldLocation, FLinearColor(0.73, 0.00, 0.62), ShootVolume.ArrowSize, ShootVolume.LineThickness);
	}
#endif
}