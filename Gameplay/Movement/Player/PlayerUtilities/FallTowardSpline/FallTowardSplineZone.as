/**
 * A Zone that will steer the player towards the spline if the player is falling in the spline direction
 */
class AFallTowardSplineZone : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.32, 0.34, 0.59));

	UPROPERTY(EditInstanceOnly)
	ASplineActor GuideSpline;

	UPROPERTY(EditInstanceOnly)
	float GuideRadius = 100;

	UPROPERTY(EditInstanceOnly)
	UPlayerAirMotionSettings AirMotionOverrideSettings;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;
	default RequestComponent.PlayerCapabilities.Add(n"FallTowardsSplineCapability");

	UPROPERTY(DefaultComponent)
	UFallTowardSplineZoneVisualizerComponent DebugComponent;

	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Player.ApplySettings(AirMotionOverrideSettings, this);

		// Setup all the guide settings
		auto Component = UFallTowardsSplineComponent::GetOrCreate(Player);
		Component.Spline = GuideSpline.Spline;
		Component.GuideRadius = GuideRadius;

		Super::TriggerOnPlayerEnter(Player);
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Player.ClearSettingsByInstigator(this);
		UFallTowardsSplineComponent::GetOrCreate(Player).Spline = nullptr;
		Super::TriggerOnPlayerLeave(Player);
	}
}