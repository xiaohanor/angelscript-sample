UCLASS(Meta = (HighlightPlacement))
class ASwimmingVolume : AHazePostProcessVolume
{
	default BrushColor = FLinearColor(0.0, 0.5, 1.0);
	default BrushComponent.LineThickness = 4.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	/*
		Post Process Volume Settings
	*/
	default Priority = 2.0;
	default BlendRadius = 20.0;

	default Settings.SetbOverride_BloomIntensity(true);
	default Settings.BloomIntensity = 1.0;
	default Settings.VignetteIntensity = 0.8;

	// DoF
	default Settings.SetbOverride_DepthOfFieldNearTransitionRegion(true);
	default Settings.DepthOfFieldNearTransitionRegion = 15000.0;
	default Settings.SetbOverride_DepthOfFieldFarTransitionRegion(true);
	default Settings.DepthOfFieldFarTransitionRegion = 300000.0;

	// Exposure
	default Settings.SetbOverride_AutoExposureMinBrightness(true);
	default Settings.AutoExposureMinBrightness = 0.3;
	default Settings.SetbOverride_AutoExposureMaxBrightness(true);
	default Settings.AutoExposureMaxBrightness = 0.8;

	// White Balance
	default Settings.SetbOverride_WhiteTemp(true);
	default Settings.WhiteTemp = 6000.0;

	// Misc
	default Settings.SetbOverride_SceneColorTint(true);
	default Settings.SceneColorTint = FLinearColor(0.098960, 0.512655, 0.828125);
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(Category = "Swimming Settings", EditAnywhere, BlueprintReadOnly)
	const EPlayerSwimmingActiveState SwimmingState = EPlayerSwimmingActiveState::Active;

	UPROPERTY(Category = "Swimming Settings", EditAnywhere, BlueprintReadOnly)
	EInstigatePriority StatePriority = EInstigatePriority::Normal;

	UPROPERTY(Category = "Swimming Settings", EditInstanceOnly)
	EHazeSelectPlayer UsableByPlayer;
	default UsableByPlayer = EHazeSelectPlayer::Both;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(!Player.IsSelectedBy(UsableByPlayer))
			return;

		UPlayerSwimmingComponent::GetOrCreate(Player).SwimmingVolumeEntered(this, SwimmingState, StatePriority);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPlayerSwimmingComponent::GetOrCreate(Player).SwimmingVolumeExited(this);
	}
}

class USwimmingVolumeDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = ASwimmingVolume;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"Swimming Settings", CategoryType = EScriptDetailCategoryType::Important);
	}
}