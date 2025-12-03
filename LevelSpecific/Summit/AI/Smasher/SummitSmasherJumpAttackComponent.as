class USummitSmasherJumpAttackComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SmashCameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SmashRumble;

	UPROPERTY()
	FVector AttackLocation;

	float ExtraVerticalVelocity = 0.0;

	float FeedbackLastHitTime;
	float FeedbackBufferTime = 0.5;

	void PlayFeedback()
	{
		if ((Time::GameTimeSeconds - FeedbackLastHitTime) < FeedbackBufferTime)
			return;

		FeedbackLastHitTime = Time::GameTimeSeconds;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(SmashCameraShake, this, 0.35);
			Player.PlayForceFeedback(SmashRumble, false, false, this, 0.75);
		}
	}
}
