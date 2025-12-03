
class UCarChaseTetherPointComponent : UContextualMovesTargetableComponent
{
	default AdditionalVisibleRange = 1500.0;
	default bTestCollision = false;

	UPROPERTY(Category = "Settings", EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides, ClampMin="400.0"))
	float TetherLength = 1250.0;

	UPROPERTY(Category = "Settings", EditAnywhere)
	UCarChaseTetherPlayerSettings PlayerSettingsAsset;

	// Will be activated when you activate the Tether point, and cleared when you stop Tethering
	UPROPERTY(Category = "Settings|Camera", EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings = nullptr;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRange(Query, ActivationRange);
		Targetable::ScoreLookAtAim(Query, false);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange);

		if(bTestCollision)
			return Targetable::RequireNotOccludedFromCamera(Query);
		
		return true;
	}

	void ApplySettings(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(PlayerSettingsAsset != nullptr)
			Player.ApplySettings(PlayerSettingsAsset, this);
		else
			UCarChaseTetherPlayerSettings::SetTetherLength(Player, TetherLength, Instigator);
	}
}