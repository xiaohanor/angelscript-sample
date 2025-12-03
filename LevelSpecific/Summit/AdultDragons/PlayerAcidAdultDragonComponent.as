
class UPlayerAcidAdultDragonComponent : UPlayerAdultDragonComponent
{
	UPROPERTY()
	TSubclassOf<UCrosshairWidget> AcidShotCrosshair;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> AcidBeamCameraShake;

	UPROPERTY()
	TSubclassOf<AAcidPuddle> PuddleClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> AcidProjectileCameraShake;

	UPROPERTY()
	UForceFeedbackEffect AcidFireRumble;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> AcidTargetableWidget;

	UPROPERTY()
	TSubclassOf<APlayerAdultDragonAimWidget> AimWidgetClass;

	bool bIsFiringAcid = false;
	float RemainingAcidAlpha = 1.0;

	FVector AimDirection;
	FVector AimOrigin;

	default PlayerAttachSocket = n"Spine3";
	default AttachmentOffset = FVector::ZeroVector;

	APlayerAdultDragonAimWidget AimWidget;

	void AlterAcidAlpha(float Amount)
	{
		RemainingAcidAlpha += Amount;
		RemainingAcidAlpha = Math::Clamp(RemainingAcidAlpha, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//SetupCameraBoolToggle();
		if(AimWidgetClass != nullptr)
		{
			AimWidget = SpawnActor(AimWidgetClass);
			AimWidget.AttachToComponent(Owner.RootComponent);
			AimWidget.AddActorDisable(this);
		}
	}
	//Helper Functions
	UFUNCTION()
	void ApplyNewAimOffset(AHazeActor Actor, FVector2D Offset, FInstigator Instigator, EHazeSettingsPriority Priority = EHazeSettingsPriority::Script)
	{
		UPlayerAimingSettings::SetScreenSpaceAimOffset(Actor, FVector2D(Offset), Instigator, Priority);
	}

	UFUNCTION()
	void ClearAimOffsetByInstigator(AHazeActor Actor, FInstigator Instigator, EHazeSettingsPriority Priority = EHazeSettingsPriority::Script)
	{
		UPlayerAimingSettings::ClearScreenSpaceAimOffset(Actor, Instigator, Priority);
	}
};