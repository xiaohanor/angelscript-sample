
UCLASS(Abstract)
class UGameplay_Character_Boss_Summit_Decimator_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartNewSpearShower(){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphNewSpearShower(){}

	UFUNCTION(BlueprintEvent)
	void OnSpearShowerFinished(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinChargeStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinChargeStop(){}

	UFUNCTION(BlueprintEvent)
	void OnShockwave(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinChargeImpactWall(FDecimatorTopDownSpinChargeImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPermaKnockedOut(){}

	UFUNCTION(BlueprintEvent)
	void OnKnockedOut(){}

	UFUNCTION(BlueprintEvent)
	void OnRecoverFromKnockout(){}

	UFUNCTION(BlueprintEvent)
	void OnWeakPointHit(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter SpearEmitter;

	UPROPERTY(BlueprintReadWrite)
	bool bIsPermaKnockedDown = false;

	AAISummitDecimatorTopdown Decimator;

	USummitDecimatorTopdownFollowSplineComponent PushSplineFollowComp;

	FVector PreviousDecimatorPos;

	const float MAX_KNOCKDOWN_PUSH_SPEED = 8.0;

	UFUNCTION(BlueprintEvent)
	void SetupTopDown() {};

	UFUNCTION(BlueprintEvent)
	void OnHeadMelt() {};

	UFUNCTION(BlueprintEvent)
	void TickPermaKnockdown(float DeltaSeconds, float PushSpeed, float PushDistanceAlpha) {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Decimator = Cast<AAISummitDecimatorTopdown>(HazeOwner);
		if(Decimator != nullptr)
		{
			PushSplineFollowComp = USummitDecimatorTopdownFollowSplineComponent::Get(Decimator);
			SetupTopDown();

			Decimator.MeltComp.OnMelted.AddUFunction(this, n"OnHeadMelt");
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(Decimator.SpearManager.IsSpawningSpears())
		{
			const FVector SpearLocation = Decimator.SpearManager.GetCurrentSpawnLocation();
			FVector2D _;

			float ScreenPanningValue = 0.0;
			float _Y;
			Audio::GetScreenPositionRelativePanningValue(SpearLocation, _, ScreenPanningValue, _Y);
			SpearEmitter.AudioComponent.SetWorldLocation(SpearLocation);
			SpearEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, ScreenPanningValue, 0.0);
		}

		FVector2D _;
		float _Y;
		float ScreenPanningValue = 0.0;
		Audio::GetScreenPositionRelativePanningValue(Decimator.Mesh.WorldLocation, _, ScreenPanningValue, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, ScreenPanningValue, 0.0);

		if(bIsPermaKnockedDown)
		{
			float PushAlpha = PushSplineFollowComp.Spline.Spline.GetClosestSplineDistanceToWorldLocation(Decimator.Mesh.WorldLocation) / PushSplineFollowComp.Spline.Spline.SplineLength;
			float PushSpeed = (Decimator.ActorLocation - PreviousDecimatorPos).Size() / MAX_KNOCKDOWN_PUSH_SPEED;	

			TickPermaKnockdown(DeltaSeconds, Math::Saturate(PushSpeed), Math::Saturate(PushAlpha));
		}

		PreviousDecimatorPos = Decimator.ActorLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Head Melt Alpha"))
	float GetMeltAlpha()
	{
		return Decimator.MeltComp.GetMeltAlpha();
	}
}