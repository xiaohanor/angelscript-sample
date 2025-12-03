class AStormKnightGem : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachToOwnerComp;
	default AttachToOwnerComp.AttachmentRule = EAttachmentRule::SnapToTarget;
}