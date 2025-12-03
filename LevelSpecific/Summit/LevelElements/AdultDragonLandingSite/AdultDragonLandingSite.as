class UAdultDragonLandingSiteTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"Interaction";
	default bShowWhileDisabled = false;
	
	UPROPERTY()
	float MaxRange = 30000;

	UPROPERTY()
	float VisibleRange = 40000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		Targetable::ApplyVisibleRange(Query, MaxRange);
		Targetable::ScoreLookAtAim(Query);
		Targetable::RequirePlayerCanReachUnblocked(Query, false);

		AAdultDragonLandingSite LandingSite = Cast<AAdultDragonLandingSite>(Owner);
		if(LandingSite.bLandingSiteOccupied)
			return false;

		if(Query.DistanceToTargetable > VisibleRange)
			return false;

		return true;
	}
}

class UAdultDragonLandingSiteHornTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"Interaction";

	UPROPERTY()
	float MaxRange = 5000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		return true;
	}
}

event void FAdultDragonOnBlowAdultDragonLandingSiteHorn();

UCLASS(Abstract)
class AAdultDragonLandingSite : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UAdultDragonLandingSiteTargetableComponent TargetableComponent;

	UPROPERTY(DefaultComponent, Attach=Root)
	UAdultDragonLandingSiteHornTargetableComponent HornTargetableComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BlowEffectRoot;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	FAdultDragonOnBlowAdultDragonLandingSiteHorn OnBlowHorn;

	AHazePlayerCharacter LandingPlayer;

	float TimeUntilNextAvailableBlow;

	UPROPERTY()
	bool bLandingSiteOccupied = false;

	bool HornBlowAvailable()
	{
		return Time::GameTimeSeconds > TimeUntilNextAvailableBlow;
	}

	UFUNCTION()
	void ForceCancel()
	{
		UAdultDragonLandingSiteComponent::Get(LandingPlayer).bForceExitLandingSite = true;
	}
}