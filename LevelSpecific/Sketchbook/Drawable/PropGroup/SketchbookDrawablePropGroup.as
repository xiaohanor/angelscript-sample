UCLASS(NotBlueprintable)
class ASketchbookDrawablePropGroup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, ShowOnActor)
	USketchbookDrawablePropGroupComponent DrawableComp;

	UPROPERTY(DefaultComponent, ShowOnActor, DisplayName = "Audio")
	USketchbookDrawablePropGroupAudioComponent DrawableAudioComp;	

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SetWorldScale3D(FVector(1));
	default EditorIcon.SpriteName = "S_Solver";
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FVector Location = ActorLocation;
		Location.X = 0;
		SetActorLocation(Location);
	}

	private bool bDebugPropGroups = false;

	UFUNCTION()
	void OnToggleDebugAudio(bool bDebug)
	{
		bDebugPropGroups = bDebug;
	}
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sketchbook::DrawableProps::AudioDebugProps.BindOnChanged(this, n"OnToggleDebugAudio");
		Sketchbook::DrawableProps::AudioDebugProps.MakeVisible();
		bDebugPropGroups = Sketchbook::DrawableProps::AudioDebugProps.IsEnabled();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Log = TEMPORAL_LOG(Game::GetMio(), "Audio/DrawableProps");
		Log.Value(f"Groups;{GetName().ToString()}", DrawableComp.GetDrawnFraction());			
	}
#endif
};