class AVillageOgre_BarrelLoader : AVillageOgreBase
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LoadAnim;

	void PlayLoadAnimation()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LoadAnim;
		AnimParams.BlendTime = 0.0;
		AnimParams.BlendOutTime = 0.0;
		AnimParams.bPauseAtEnd = true;
		PlaySlotAnimation(AnimParams);
	}
}