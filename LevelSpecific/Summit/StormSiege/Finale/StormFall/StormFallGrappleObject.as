class AStormFallGrappleObject : AStormFallObject
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UGrapplePointComponent GrappleComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent EditorIcon;

	UPROPERTY(DefaultComponent)
	UGrappleLaunchPointDrawComponent DrawComp;
#endif

}