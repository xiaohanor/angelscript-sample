/**
 * Helper volume for implementing progress points.
 * 
 * When any player first enters this volume, the specified progress point is activated.
 * 
 * NB: The progress point must be prepared first, or you will get an error!
 * 
 * NB: Starts disabled! Progress point volumes must be explicitly enabled
 * before they can be used.
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class AProgressPointTrigger : AVolume
{
	default BrushColor = FLinearColor(0.74, 0.68, 0.11);
	default BrushComponent.LineThickness = 10.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Sprite;
	default Sprite.SpriteName = "Progress";
	default Sprite.RelativeScale3D = FVector(2.0);
#endif
	
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Progress Point Trigger")
    bool bTriggerForMio = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Progress Point Trigger")
    bool bTriggerForZoe = true;

	/**
	 * Which progress point to activate when the volume is entered by a player.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Progress Point Trigger")
    FHazeProgressPointRef ActivateProgressPoint;

	private bool bEnabled = false;
	private bool bTriggeredProgressPoint = false;

	/**
	 * Enable this progress point volume permanently, until one of the players enters it.
	 */
	UFUNCTION()
	void EnableProgressPointTrigger()
	{
		bEnabled = true;

		if (!bTriggeredProgressPoint)
		{
			for (auto Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;

				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					ReceiveBeginOverlap(Player);
			}
		}
	}

	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (!bEnabled)
			return false;

		if (Player.IsMio())
		{
			if (!bTriggerForMio)
				return false;
		}
		else
		{
			if (!bTriggerForZoe)
				return false;
		}

		return true;
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		ReceiveBeginOverlap(OtherActor);
	}

	private void ReceiveBeginOverlap(AActor OtherActor)
	{
		if (bTriggeredProgressPoint)
			return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		if (!Player.HasControl())
			return;
        if (!IsEnabledForPlayer(Player))
            return;

		CrumbTriggerProgressPoint();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerProgressPoint()
	{
		if (bTriggeredProgressPoint)
			return;

		bTriggeredProgressPoint = true;
		Progress::ActivateProgressPoint(Progress::GetProgressPointRefID(ActivateProgressPoint));
	}
}

#if EDITOR
class UProgressPointTriggerDetails : UHazeScriptDetailCustomization
{
	default DetailClass = AProgressPointTrigger;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		AProgressPointTrigger Trigger = Cast<AProgressPointTrigger>(GetCustomizedObject());

		Drawer = AddImmediateRow(n"Progress Point Trigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AProgressPointTrigger Trigger = Cast<AProgressPointTrigger>(GetCustomizedObject());
		if (Trigger == nullptr)
			return;

		// Set a nice actor label 
		FString Label = Trigger.GetActorLabel();
		if (Label.StartsWith("ProgressPointTrigger "))
		{
			FString TargetName = Trigger.ActivateProgressPoint.Name;
			FString LevelName = Progress::GetShortLevelName(Progress::GetLevelGroup(Trigger.ActivateProgressPoint.InLevel));

			FString WantedLabel = f"ProgressPointTrigger → {TargetName} ({LevelName})";
			if (WantedLabel != Label)
			{
				Editor::SetActorLabelUnique(Trigger, WantedLabel);
			}
		}

		// Show the warning
		if (Drawer.IsVisible())
		{
			auto Box = Drawer.BeginVerticalBox();
			Box.Text("NOTE:").Bold().Scale(1.2);
			Box.Text("• Progress point triggers must be enabled from the level blueprint with EnableProgressPointTrigger()").AutoWrapText();
			Box.Text("• The selected progress point must be prepared before the progress point trigger is enabled!").AutoWrapText();
			Box.Spacer(20);

			Drawer.End();
		}
	}
}
#endif