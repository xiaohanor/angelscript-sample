class AVillageOgre_BarrelThrower : AVillageOgreBase
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeftAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MidAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence RightAnim;

	UFUNCTION()
	void PlayAnimation(EVillageBarrelThrowSide Side)
	{
		UAnimSequence Anim;
		switch (Side)
		{
			case EVillageBarrelThrowSide::Left:
				Anim = LeftAnim;
			break;
			case EVillageBarrelThrowSide::Mid:
				Anim = MidAnim;
			break;
			case EVillageBarrelThrowSide::Right:
				Anim = RightAnim;
			break;
		}

		PlaySlotAnimation(Animation = Anim);
	}
}