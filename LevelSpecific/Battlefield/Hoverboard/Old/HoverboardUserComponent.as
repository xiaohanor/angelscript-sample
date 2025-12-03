class UHoverboardUserComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AHoverboard> HoverboardClass;

	UPROPERTY(EditAnywhere)
	UAnimSequence StandAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence GrabAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence JumpAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence LandAnimation;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BoneFilter;	

	AHoverboard Hoverboard;

	FVector2D Input;
	FVector2D Lean;
}