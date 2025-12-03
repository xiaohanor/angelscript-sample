namespace Arena
{
	AArenaBoss GetBoss()
	{
		return TListedActors<AArenaBoss>().Single;
	}
}